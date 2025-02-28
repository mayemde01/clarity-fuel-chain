import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test batch creation",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('fuel-chain', 'create-batch', 
        [types.uint(1000), types.ascii("DIESEL"), types.uint(95)], 
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectUint(0);
    
    // Verify batch info
    let response = chain.callReadOnlyFn(
      'fuel-chain', 
      'get-batch-info',
      [types.uint(0)],
      deployer.address
    );
    response.result.expectOk();
  }
});

Clarinet.test({
  name: "Test fuel transfer",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Create initial batch
    chain.mineBlock([
      Tx.contractCall('fuel-chain', 'create-batch',
        [types.uint(1000), types.ascii("DIESEL"), types.uint(95)],
        deployer.address
      )
    ]);
    
    // Test transfer
    let block = chain.mineBlock([
      Tx.contractCall('fuel-chain', 'transfer-fuel',
        [types.uint(500), types.principal(deployer.address), types.principal(wallet1.address)],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Verify balances
    let response = chain.callReadOnlyFn(
      'fuel-chain',
      'get-inventory',
      [types.principal(wallet1.address)],
      deployer.address
    );
    response.result.expectOk().expectUint(500);
  }
});

Clarinet.test({
  name: "Test quality verification",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    // Create batch
    chain.mineBlock([
      Tx.contractCall('fuel-chain', 'create-batch',
        [types.uint(1000), types.ascii("DIESEL"), types.uint(95)],
        deployer.address
      )
    ]);
    
    // Test quality verification
    let block = chain.mineBlock([
      Tx.contractCall('fuel-chain', 'verify-quality',
        [types.uint(0), types.uint(96)],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectBool(true);
  }
});
