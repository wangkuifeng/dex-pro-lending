package indexer

import (
	"log"

	"dex-pro-lending-backend/internal/bindings"
	"dex-pro-lending-backend/internal/db"
	"dex-pro-lending-backend/internal/models"

	"github.com/ethereum/go-ethereum/common"
)

// StartIndexer 启动全局事件监听引擎
func StartIndexer(contractAddress string) {
	poolAddress := common.HexToAddress(contractAddress)

	// 1. 实例化 Pool 的过滤器 (只读，不需要私钥)
	filterer, err := bindings.NewPoolFilterer(poolAddress, EthClient)
	if err != nil {
		log.Fatalf("❌ 无法实例化 Pool Filterer: %v", err)
	}

	log.Printf("📡 开始监听 Pool 合约事件: %s", contractAddress)

	// 2. 开启独立的协程，互不阻塞地监听各个事件
	go watchSupply(filterer)
	go watchBorrow(filterer)

	// TODO: 后续补齐 watchWithdraw(filterer) 和 watchRepay(filterer)
}

// watchSupply 监听存款事件
func watchSupply(filterer *bindings.PoolFilterer) {
	// 创建接收事件的管道
	sink := make(chan *bindings.PoolSupply)
	// 启动订阅
	sub, err := filterer.WatchSupply(nil, sink, nil, nil)
	if err != nil {
		log.Printf("❌ 订阅 Supply 事件失败: %v", err)
		return
	}
	defer sub.Unsubscribe()

	// 死循环处理管道数据
	for {
		select {
		case err := <-sub.Err():
			log.Printf("⚠️ Supply 监听异常中断: %v", err)
			return // 生产环境中这里需要写重连逻辑
		case ev := <-sink:
			log.Printf("📥 [链上捕获] Supply! 用户: %s, 金额: %s", ev.User.Hex(), ev.Amount.String())

			// 组装数据库模型
			txLog := models.Transaction{
				TxHash:       ev.Raw.TxHash.Hex(),
				LogIndex:     uint(ev.Raw.Index),
				BlockNumber:  ev.Raw.BlockNumber,
				EventType:    "Supply",
				UserAddress:  ev.User.Hex(),
				AssetAddress: ev.Reserve.Hex(),
				Amount:       ev.Amount.String(),
				Timestamp:    0, // Phase 1 简化：严格来说需要通过 RPC 查区块头获取时间，这里暂填 0
			}

			// 写入 MySQL (依赖 tx_hash 和 log_index 联合唯一索引防重发)
			if err := db.DB.Create(&txLog).Error; err != nil {
				log.Printf("⚠️ 写入 Supply 失败 (可能已存在): %v", err)
			} else {
				log.Printf("✅ Supply 流水已安全入库!")
			}
		}
	}
}

// watchBorrow 监听借款事件
func watchBorrow(filterer *bindings.PoolFilterer) {
	sink := make(chan *bindings.PoolBorrow)
	sub, err := filterer.WatchBorrow(nil, sink, nil, nil)
	if err != nil {
		log.Printf("❌ 订阅 Borrow 事件失败: %v", err)
		return
	}
	defer sub.Unsubscribe()

	for {
		select {
		case err := <-sub.Err():
			log.Printf("⚠️ Borrow 监听异常中断: %v", err)
			return
		case ev := <-sink:
			log.Printf("📥 [链上捕获] Borrow! 用户: %s, 金额: %s", ev.User.Hex(), ev.Amount.String())

			txLog := models.Transaction{
				TxHash:       ev.Raw.TxHash.Hex(),
				LogIndex:     uint(ev.Raw.Index),
				BlockNumber:  ev.Raw.BlockNumber,
				EventType:    "Borrow",
				UserAddress:  ev.User.Hex(),
				AssetAddress: ev.Reserve.Hex(),
				Amount:       ev.Amount.String(),
				Timestamp:    0,
			}

			if err := db.DB.Create(&txLog).Error; err != nil {
				log.Printf("⚠️ 写入 Borrow 失败: %v", err)
			} else {
				log.Printf("✅ Borrow 流水已安全入库!")
			}
		}
	}
}
