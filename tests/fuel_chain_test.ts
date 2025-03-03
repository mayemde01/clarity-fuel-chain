import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test contract pause functionality",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('fuel-chain', 'pause-contract', [], deployer.address)
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Try creating batch while paused
    block = chain.mineBlock([
      Tx.contractCall('fuel-chain', 'create-batch', 
        [types.uint(1000), types.ascii("DIESEL"), types.uint(95)], 
        deployer.address
      )
    ]);
    
    block.receipts[0].result.expectErr().expectUint(105); // err-paused
  }
});

// Original tests remain unchanged...
[Previous test content]
