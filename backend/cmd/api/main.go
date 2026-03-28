// backend/main.go
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
	// 1. 加载环境变量
	if err := godotenv.Load(); err != nil {
		log.Println("⚠️ 未找到 .env 文件，将使用系统环境变量")
	}

	// 2. 初始化 MySQL 数据库连接与表结构迁移
	db.InitDB()

	// 3. 建立 go-ethereum RPC 节点连接
	rpcURL := os.Getenv("RPC_URL")
	if rpcURL == "" {
		rpcURL = "ws://127.0.0.1:8545" // 默认连接本地 Anvil 的 WebSocket
	}
	indexer.InitEthClient(rpcURL)

	// 4. 启动后台事件监听器 (Goroutine 常驻，无阻塞)
	poolAddress := os.Getenv("POOL_CONTRACT_ADDRESS")
	if poolAddress == "" {
		poolAddress = "0x53da77297453cEA71949fB260335E3eC7ce0Cf25" // 替换为 Anvil 实际部署的 Pool 地址
	}
	go indexer.StartIndexer(poolAddress)

	// 5. 启动 Gin 引擎
	r := gin.Default()

	// 6. 配置 CORS 跨域中间件 (极简版，完美放行 Next.js 3000/3001 端口的本地请求)
	r.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Origin, Content-Type, Authorization")

		// 拦截浏览器的 OPTIONS 预检请求并直接返回 204 成功
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		c.Next()
	})

	// 7. 挂载业务 API 路由 (/api/markets, /api/users/:address 等)
	api.SetupRoutes(r)

	// 8. 启动服务器
	log.Println("🚀 API Server 启动于 :8080")
	if err := r.Run(":8080"); err != nil {
		log.Fatalf("服务器启动失败: %v", err)
	}
}
