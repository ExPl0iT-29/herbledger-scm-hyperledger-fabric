package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// HerbLedgerContract defines the smart contract for HerbLedger
type HerbLedgerContract struct {
	contractapi.Contract
}

// Batch represents a herb batch in the supply chain
type Batch struct {
	ID             string    `json:"id"`
	Species        string    `json:"species"`
	GPS            string    `json:"gps"`
	Timestamp      time.Time `json:"timestamp"`
	CollectorID    string    `json:"collectorID"`
	Status         string    `json:"status"`
	ProcessingInfo string    `json:"processingInfo"`
	QualityResults string    `json:"qualityResults"`
	QRCode         string    `json:"qrCode"`
	HashOffchain   string    `json:"hashOffchain"`
}

// CreateBatch creates a new batch with geo-fencing check
func (s *HerbLedgerContract) CreateBatch(ctx contractapi.TransactionContextInterface, id, species, gps, collectorID string) error {
	if !s.validateGeoFence(gps) {
		return fmt.Errorf("GPS %s outside approved zone", gps)
	}
	existing, err := ctx.GetStub().GetState(id)
	if err != nil {
		return fmt.Errorf("failed to read world state: %v", err)
	}
	if existing != nil {
		return fmt.Errorf("batch %s exists", id)
	}
	batch := Batch{
		ID:          id,
		Species:     species,
		GPS:         gps,
		Timestamp:   time.Now(),
		CollectorID: collectorID,
		Status:      "COLLECTED",
	}
	batchJSON, err := json.Marshal(batch)
	if err != nil {
		return err
	}
	return ctx.GetStub().PutState(id, batchJSON)
}

// UpdateProcessing updates batch with processing details
func (s *HerbLedgerContract) UpdateProcessing(ctx contractapi.TransactionContextInterface, id, processorID, method string) error {
	batch, err := s.getBatch(ctx, id)
	if err != nil {
		return err
	}
	if batch.Status != "COLLECTED" {
		return fmt.Errorf("batch %s not ready for processing", id)
	}
	batch.ProcessingInfo = fmt.Sprintf("Processed by %s: %s", processorID, method)
	batch.Status = "PROCESSED"
	return s.putBatch(ctx, id, batch)
}

// RecordQualityTest logs test results and compliance
func (s *HerbLedgerContract) RecordQualityTest(ctx contractapi.TransactionContextInterface, id, results, certificateHash string) error {
	batch, err := s.getBatch(ctx, id)
	if err != nil {
		return err
	}
	if batch.Status != "PROCESSED" {
		return fmt.Errorf("batch %s not processed", id)
	}
	if !s.validateCompliance(results) {
		return fmt.Errorf("quality test failed NMPB compliance")
	}
	batch.QualityResults = results
	batch.HashOffchain = certificateHash
	batch.Status = "TESTED"
	return s.putBatch(ctx, id, batch)
}

// GenerateQRMapping finalizes batch with QR code
func (s *HerbLedgerContract) GenerateQRMapping(ctx contractapi.TransactionContextInterface, id, qrCode string) error {
	batch, err := s.getBatch(ctx, id)
	if err != nil {
		return err
	}
	if batch.Status != "TESTED" {
		return fmt.Errorf("batch %s not tested", id)
	}
	batch.QRCode = qrCode
	batch.Status = "FINALIZED"
	return s.putBatch(ctx, id, batch)
}

// QueryBatch retrieves batch details
func (s *HerbLedgerContract) QueryBatch(ctx contractapi.TransactionContextInterface, id string) (*Batch, error) {
	return s.getBatch(ctx, id)
}

// Helpers
func (s *HerbLedgerContract) getBatch(ctx contractapi.TransactionContextInterface, id string) (*Batch, error) {
	batchJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return nil, fmt.Errorf("failed to read: %v", err)
	}
	if batchJSON == nil {
		return nil, fmt.Errorf("batch %s not found", id)
	}
	var batch Batch
	err = json.Unmarshal(batchJSON, &batch)
	return &batch, err
}

func (s *HerbLedgerContract) putBatch(ctx contractapi.TransactionContextInterface, id string, batch *Batch) error {
	batchJSON, err := json.Marshal(batch)
	if err != nil {
		return err
	}
	return ctx.GetStub().PutState(id, batchJSON)
}

func (s *HerbLedgerContract) validateGeoFence(gps string) bool {
	// Stub: Approved zone (e.g., Kerala)
	return gps == "12.9716,77.5946" // Replace with real geo-fence logic
}

func (s *HerbLedgerContract) validateCompliance(results string) bool {
	// Stub: NMPB pesticide threshold
	return results != "pesticides:0.2" // Replace with real checks
}

func main() {
	chaincode, err := contractapi.NewChaincode(&HerbLedgerContract{})
	if err != nil {
		fmt.Printf("Error creating chaincode: %v", err)
		return
	}
	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting chaincode: %v", err)
	}
}