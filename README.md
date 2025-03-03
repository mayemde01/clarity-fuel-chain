# FuelChain
A tokenized system for managing fuel logistics on the Stacks blockchain.

## Features
- Fuel token creation and management
- Supply chain tracking for fuel deliveries
- Batch tracking with quality metrics
- Transfer and trading of fuel tokens
- Real-time fuel inventory management
- Emergency pause functionality
- Event logging system
- Enhanced batch status tracking

## Setup and Installation
1. Clone the repository
2. Install Clarinet 
3. Run `clarinet check` to verify contracts
4. Run `clarinet test` to execute tests

## Usage Examples
```clarity
;; Create new fuel batch
(contract-call? .fuel-chain create-batch u1000 "DIESEL" u95)

;; Transfer fuel tokens
(contract-call? .fuel-chain transfer-fuel u100 'ST1... 'ST2...)

;; Check fuel inventory
(contract-call? .fuel-chain get-inventory 'ST1...)

;; Update batch status
(contract-call? .fuel-chain update-batch-status u0 "COMPLETED")
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment

## Security Features
- Contract pause mechanism for emergency situations
- Event logging for all important operations
- Enhanced access control
- Comprehensive error handling
