# Vaultify NFT Marketplace

A comprehensive NFT marketplace smart contract built on the Stacks blockchain using Clarity. Vaultify enables creators to mint, trade, and manage digital collectibles with built-in royalty mechanisms.

## Features

- **NFT Minting**: Create unique digital assets with custom metadata
- **Marketplace Trading**: List and purchase NFTs with STX payments
- **Royalty System**: Automatic creator compensation on secondary sales
- **Administrative Controls**: Platform management and ownership transfer
- **Secure Validation**: Input sanitization and permission checks

## Smart Contract Functions

### Administrative Functions

#### `update-admin-role`
```clarity
(update-admin-role (successor principal))
```
Transfers platform administrative privileges to a new principal address.
- **Parameters**: `successor` - The new administrator's principal
- **Access**: Current administrator only
- **Returns**: `(ok true)` on success

#### `get-admin-info`
```clarity
(get-admin-info)
```
Retrieves the current platform administrator's principal.
- **Returns**: `(ok principal)` - Current administrator address

### Asset Creation

#### `forge-asset`
```clarity
(forge-asset (metadata-link (string-ascii 256)) (creator-fee uint))
```
Mints a new digital collectible NFT.
- **Parameters**:
  - `metadata-link` - URI pointing to asset metadata (max 256 characters)
  - `creator-fee` - Royalty percentage in basis points (max 1000 = 10%)
- **Returns**: `(ok uint)` - The newly created asset ID

### Marketplace Operations

#### `offer-for-trade`
```clarity
(offer-for-trade (asset-id uint) (asking-amount uint))
```
Lists an NFT for sale on the marketplace.
- **Parameters**:
  - `asset-id` - The NFT identifier to list
  - `asking-amount` - Sale price in microSTX
- **Access**: Asset owner only
- **Returns**: `(ok true)` on successful listing

#### `withdraw-offer`
```clarity
(withdraw-offer (asset-id uint))
```
Removes an NFT from marketplace listings.
- **Parameters**: `asset-id` - The NFT identifier to delist
- **Access**: Current seller only
- **Returns**: `(ok true)` on successful removal

#### `acquire-asset`
```clarity
(acquire-asset (asset-id uint))
```
Purchases a listed NFT from the marketplace.
- **Parameters**: `asset-id` - The NFT identifier to purchase
- **Process**:
  1. Calculates creator royalty payment
  2. Transfers royalty to original creator
  3. Transfers remaining amount to seller
  4. Transfers NFT ownership to buyer
  5. Removes listing from marketplace
- **Returns**: `(ok true)` on successful purchase

### Query Functions

#### `fetch-asset-data`
```clarity
(fetch-asset-data (asset-id uint))
```
Retrieves comprehensive information about a digital asset.
- **Parameters**: `asset-id` - The NFT identifier to query
- **Returns**: Asset details including holder, originator, metadata link, and creator fee

#### `fetch-market-data`
```clarity
(fetch-market-data (asset-id uint))
```
Retrieves marketplace listing information for an asset.
- **Parameters**: `asset-id` - The NFT identifier to query
- **Returns**: Listing details including asking amount and vendor

## Data Structures

### Digital Assets Map
```clarity
{ asset-id: uint } -> {
  holder: principal,           // Current NFT owner
  originator: principal,       // Original creator
  metadata-link: (string-ascii 256), // Metadata URI
  creator-fee: uint           // Royalty in basis points
}
```

### Marketplace Entries Map
```clarity
{ asset-id: uint } -> {
  asking-amount: uint,        // Price in microSTX
  vendor: principal          // Current seller
}
```

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | `unauthorized-access` | Caller lacks administrative privileges |
| 101 | `insufficient-permissions` | Caller doesn't own the specified asset |
| 102 | `market-entry-missing` | Requested listing doesn't exist |
| 103 | `amount-below-minimum` | Price must be greater than zero |
| 104 | `asset-identifier-invalid` | Asset ID is invalid or doesn't exist |
| 105 | `metadata-format-error` | Metadata URI is empty or invalid |
| 106 | `commission-rate-exceeded` | Royalty percentage exceeds 10% limit |

## Usage Examples

### Minting an NFT
```clarity
;; Mint NFT with 5% royalty
(contract-call? .artvault forge-asset "https://api.example.com/metadata/1" u500)
```

### Listing for Sale
```clarity
;; List asset #1 for 100 STX
(contract-call? .artvault offer-for-trade u1 u100000000)
```

### Purchasing an NFT
```clarity
;; Buy asset #1
(contract-call? .artvault acquire-asset u1)
```

### Checking Asset Details
```clarity
;; Get information about asset #1
(contract-call? .artvault fetch-asset-data u1)
```

## Security Features

- **Input Validation**: All parameters are checked for validity
- **Permission Enforcement**: Asset operations require appropriate ownership
- **Principal Verification**: Administrator changes validate standard addresses
- **Overflow Protection**: Mathematical operations use safe arithmetic
- **State Consistency**: Atomic operations ensure data integrity

## Deployment Considerations

1. **Initial Setup**: The contract deployer becomes the initial administrator
2. **Royalty Limits**: Creator fees are capped at 10% (1000 basis points)
3. **Metadata Standards**: Ensure metadata URIs follow established NFT standards
4. **Gas Optimization**: Functions are designed for efficient execution

## Integration Guidelines

When integrating with ArtVault:

1. **Frontend Applications**: Use read-only functions for displaying marketplace data
2. **Wallet Integration**: Implement proper STX balance checks before purchases
3. **Metadata Handling**: Validate metadata URIs and ensure IPFS/HTTP accessibility
4. **Event Monitoring**: Watch for NFT transfers and marketplace events
5. **Error Handling**: Implement comprehensive error handling for all contract interactions


