package models

import (
	"gorm.io/gorm"
)

// Market 资产池状态表
type Market struct {
	gorm.Model
	AssetAddress         string `gorm:"type:varchar(42);uniqueIndex;not null" json:"asset_address"`
	Symbol               string `gorm:"type:varchar(10);not null" json:"symbol"`
	Name                 string `gorm:"type:varchar(50);not null" json:"name"`
	Decimals             uint8  `gorm:"type:tinyint;not null" json:"decimals"`
	TotalSupplyBase      string `gorm:"type:varchar(78);default:'0'" json:"total_supply_base"`
	TotalBorrowBase      string `gorm:"type:varchar(78);default:'0'" json:"total_borrow_base"`
	CurrentLiquidityRate string `gorm:"type:varchar(78);default:'0'" json:"current_liquidity_rate"`
	CurrentBorrowRate    string `gorm:"type:varchar(78);default:'0'" json:"current_borrow_rate"`
}

// User 用户快照表
type User struct {
	gorm.Model
	Address                     string `gorm:"type:varchar(42);uniqueIndex;not null" json:"address"`
	TotalCollateralBase         string `gorm:"type:varchar(78);default:'0'" json:"total_collateral_base"`
	TotalDebtBase               string `gorm:"type:varchar(78);default:'0'" json:"total_debt_base"`
	AvailableBorrowsBase        string `gorm:"type:varchar(78);default:'0'" json:"available_borrows_base"`
	CurrentLiquidationThreshold string `gorm:"type:varchar(78);default:'0'" json:"current_liquidation_threshold"`
	Ltv                         string `gorm:"type:varchar(78);default:'0'" json:"ltv"`
	HealthFactor                string `gorm:"type:varchar(78);default:'0'" json:"health_factor"`
	LastUpdateTimestamp         int64  `gorm:"autoUpdateTime" json:"last_update_timestamp"`
}

// Transaction 链上交易流水表
type Transaction struct {
	gorm.Model
	TxHash       string `gorm:"type:varchar(66);uniqueIndex:idx_tx_log;not null" json:"tx_hash"`
	LogIndex     uint   `gorm:"uniqueIndex:idx_tx_log;not null" json:"log_index"`
	BlockNumber  uint64 `gorm:"index;not null" json:"block_number"`
	EventType    string `gorm:"type:varchar(20);index;not null" json:"event_type"`
	UserAddress  string `gorm:"type:varchar(42);index;not null" json:"user_address"`
	AssetAddress string `gorm:"type:varchar(42);index;not null" json:"asset_address"`
	Amount       string `gorm:"type:varchar(78);not null" json:"amount"`
	Timestamp    int64  `gorm:"index;not null" json:"timestamp"`
}
