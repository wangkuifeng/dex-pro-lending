package main

import (
	"log"
	"os"

	"dex-pro-lending-backend/internal/api"
	"dex-pro-lending-backend/internal/db"
	"dex-pro-lending-backend/internal/indexer"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("⚠️  未找到 .env 文件，将使用系统环境变量")
	}

	// 1. 初始化数据库
	db.InitDB()

	// 2. 建立 RPC 节点连接
	rpcURL := os.Getenv("RPC_URL")
	if rpcURL == "" {
		rpcURL = "ws://127.0.0.1:8545"
	}
	indexer.InitEthClient(rpcURL)

	// 3. 启动后台事件监听器 (Goroutine 常驻)
	poolAddress := os.Getenv("POOL_CONTRACT_ADDRESS")
	if poolAddress == "" {
		poolAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3"
	}
	go indexer.StartIndexer(poolAddress)

	// 4. 启动 Gin 引擎
	r := gin.Default()

	// 5. 配置 CORS 跨域中间件 (极简版，允许所有 Next.js 本地请求)
	r.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Origin, Content-Type, Authorization")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	})

	// 6. 挂载我们刚刚写的业务 API 路由
	api.SetupRoutes(r)

	log.Println("🚀 API Server 启动于 :8080")
	if err := r.Run(":8080"); err != nil {
		log.Fatalf("服务器启动失败: %v", err)
	}
}
