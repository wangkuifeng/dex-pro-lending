package db

import (
	"fmt"
	"log"
	"os"

	"dex-pro-lending-backend/internal/models"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var DB *gorm.DB

// InitDB 初始化 MySQL 连接并自动迁移表结构
func InitDB() {
	dsn := os.Getenv("MYSQL_DSN")
	if dsn == "" {
		// 本地开发默认配置，建议在 .env 中覆盖
		dsn = "root:123456@tcp(127.0.0.1:3306)/dex_pro?charset=utf8mb4&parseTime=True&loc=Local"
	}

	var err error
	DB, err = gorm.Open(mysql.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info), // 开发环境下打印 SQL
	})
	if err != nil {
		log.Fatalf("❌ 数据库连接失败: %v", err)
	}

	fmt.Println("✅ MySQL 连接成功!")

	// 自动迁移我们定义的三个核心表
	err = DB.AutoMigrate(
		&models.Market{},
		&models.User{},
		&models.Transaction{},
	)
	if err != nil {
		log.Fatalf("❌ 数据库自动迁移失败: %v", err)
	}

	fmt.Println("✅ GORM 表结构迁移完成!")
}
