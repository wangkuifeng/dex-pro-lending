package indexer

import (
	"log"

	"github.com/ethereum/go-ethereum/ethclient"
)

// EthClient 全局复用的以太坊 RPC 客户端
var EthClient *ethclient.Client

// InitEthClient 初始化并连接节点
// 注意：监听事件推荐使用 WebSocket (ws://) 协议，而不是 HTTP (http://)
func InitEthClient(rpcURL string) {
	client, err := ethclient.Dial(rpcURL)
	if err != nil {
		log.Fatalf("❌ 无法连接到以太坊节点 (%s): %v", rpcURL, err)
	}

	EthClient = client
	log.Printf("✅ 成功连入以太坊节点: %s\n", rpcURL)
}
