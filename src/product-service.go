package main

import (
	"net/http"
	"strconv"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	// Rate: requests per endpoint
	requestsTotal = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "http_requests_total",
		Help: "Total HTTP requests.",
	}, []string{"method", "route", "status"})

	// Errors: non-2xx responses (error) per endpoint
	errorsTotal = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "http_request_errors_total",
		Help: "Total HTTP requests with a non-2xx status. (errors)",
	}, []string{"method", "route", "status"})

	// Duration: latency distribution per endpoint
	requestDuration = promauto.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "http_request_duration_seconds",
		Help:    "HTTP request latency in seconds.",
		Buckets: prometheus.DefBuckets,
	}, []string{"method", "route"})
)

// Middleware to count the routes data
func metricsMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		c.Next()

		route := c.FullPath() //Lablels /products/:productId instead of /products/1 to avoid giving each product an own time series
		if route == "/metrics" {
			return // don't count Prometheus paths as traffic
		}
		if route == "" {
			route = "unmatched" // for unknown paths
		}
		status := c.Writer.Status()
		statusLabel := strconv.Itoa(status)

		requestsTotal.WithLabelValues(c.Request.Method, route, statusLabel).Inc()
		if status < 200 || status >= 300 {
			errorsTotal.WithLabelValues(c.Request.Method, route, statusLabel).Inc()
		}
		requestDuration.WithLabelValues(c.Request.Method, route).Observe(time.Since(start).Seconds())
	}
}

// * is needed as 0 would be invalid
// required is needed here as the client fills this out (c.ShouldBindJSON will validate it)
type Product struct {
	ProductID    *int   `json:"product_id" binding:"required,gte=1"`
	SKU          string `json:"sku" binding:"required,min=1,max=100"`
	Manufacturer string `json:"manufacturer" binding:"required,min=1,max=200"`
	CategoryID   *int   `json:"category_id" binding:"required,gte=1"`
	Weight       *int   `json:"weight" binding:"required,gte=0"`
	SomeOtherID  *int   `json:"some_other_id" binding:"required,gte=1"`
}

type Error struct {
	Error   string `json:"error"`
	Message string `json:"message"`
	Details string `json:"details,omitempty"`
}

// pid maps to Product
var (
	products = map[int]Product{}
	mu       sync.RWMutex
)

func intPtr(n int) *int { return &n }

func seedProducts() {
	mu.Lock()
	defer mu.Unlock()
	products[1] = Product{
		ProductID:    intPtr(1),
		SKU:          "ABC-123-XYZ",
		Manufacturer: "Apple",
		CategoryID:   intPtr(456),
		Weight:       intPtr(1250),
		SomeOtherID:  intPtr(789),
	}
	products[2] = Product{
		ProductID:    intPtr(2),
		SKU:          "DEF-456-UVW",
		Manufacturer: "Bluetooth",
		CategoryID:   intPtr(12),
		Weight:       intPtr(0),
		SomeOtherID:  intPtr(34),
	}
}

func main() {
	seedProducts()
	r := gin.Default()
	r.Use(metricsMiddleware())

	// Prometheus scrapes this endpoint
	r.GET("/metrics", gin.WrapH(promhttp.Handler()))

	r.GET("/products/:productId", func(c *gin.Context) {
		// Read productId part and convert to string
		id, err := strconv.Atoi(c.Param("productId"))

		//If the id is invalid
		if err != nil || id < 1 {
			c.JSON(http.StatusBadRequest, Error{
				Error:   "INVALID_INPUT",
				Message: "The provided product ID is invalid",
			})
			return
		}

		mu.RLock()
		p, ok := products[id] //p = product, ok is good request
		mu.RUnlock()

		if !ok {
			// 404: pid not found
			c.JSON(http.StatusNotFound, Error{
				Error:   "NOT_FOUND",
				Message: "Product not found",
				Details: "No product exists with ID " + strconv.Itoa(id),
			})
			return
		}

		// 200: serialize the Product struct to JSON using its json tags
		c.JSON(http.StatusOK, p)
	})

	r.POST("/products/:productId/details", func(c *gin.Context) {
		// Read productId part and convert to string
		id, err := strconv.Atoi(c.Param("productId"))

		//If the id is invalid
		if err != nil || id < 1 {
			c.JSON(http.StatusBadRequest, Error{
				Error:   "INVALID_INPUT",
				Message: "The provided product ID is invalid",
			})
			return
		}

		//ShouldBindJSON decodes the provided body and enforces it matches
		//our Product schema.
		var p Product
		if err := c.ShouldBindJSON(&p); err != nil {
			c.JSON(400, Error{
				Error:   "INVALID_INPUT",
				Message: "The provided product data is invalid",
				Details: err.Error(), // says which field/rule failed
			})
			return
		}

		mu.Lock()
		defer mu.Unlock()

		if _, ok := products[id]; !ok {
			c.JSON(http.StatusNotFound, Error{
				Error:   "NOT_FOUND",
				Message: "Product not found",
				Details: "No product exists with ID " + strconv.Itoa(id),
			})
			return
		}

		products[id] = p // replace the stored product with the new details

		c.Status(http.StatusNoContent)
	})

	r.Run(":8081")
}
