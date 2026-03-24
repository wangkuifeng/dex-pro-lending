package api

import (
	"net/http"
	"strings"

	"dex-pro-lending-backend/internal/db"
	"dex-pro-lending-backend/internal/models"

	"github.com/gin-gonic/gin"
)

// SetupRoutes 注册所有的 RESTful API 路由
func SetupRoutes(r *gin.Engine) {
	api := r.Group("/api")
	{
		api.GET("/markets", GetMarkets)
		api.GET("/users/:address", GetUserSnapshot)
	}
}

// GetMarkets 获取所有资产池状态 (用于前端 Dashboard 总览)
func GetMarkets(c *gin.Context) {
	var markets []models.Market
	// 查询数据库中的所有市场数据
	if err := db.DB.Find(&markets).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "获取市场数据失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 200,
		"msg":  "success",
		"data": markets,
	})
}

// GetUserSnapshot 获取个人看板快照 (用于前端展示用户的健康因子、借贷额度)
func GetUserSnapshot(c *gin.Context) {
	address := c.Param("address")
	address = strings.ToLower(address) // EVM 地址统一转小写查询防坑

	var user models.User
	// 根据钱包地址查询用户状态
	if err := db.DB.Where("LOWER(address) = ?", address).First(&user).Error; err != nil {
		// 架构师细节：如果数据库里查不到该用户，说明是全新用户（还没存过钱）
		// 不要报 500/404 错误，而是直接返回一个全为 0 的空快照，前端渲染更优雅
		c.JSON(http.StatusOK, gin.H{
			"code": 200,
			"msg":  "new user",
			"data": models.User{
				Address:             address,
				TotalCollateralBase: "0",
				TotalDebtBase:       "0",
				HealthFactor:        "0",
			},
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": 200,
		"msg":  "success",
		"data": user,
	})
}
