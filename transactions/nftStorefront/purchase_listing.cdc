import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"
import SherpaItems from "../../contracts/SherpaItems.cdc"
import NFTStorefront from "../../contracts/NFTStorefront.cdc"

pub fun getOrCreateCollection(account: AuthAccount): &SherpaItems.Collection{NonFungibleToken.Receiver} {
    if let collectionRef = account.borrow<&SherpaItems.Collection>(from: SherpaItems.CollectionStoragePath) {
        return collectionRef
    }

    // create a new empty collection
    let collection <- SherpaItems.createEmptyCollection() as! @SherpaItems.Collection

    let collectionRef = &collection as &SherpaItems.Collection
    
    // save it to the account
    account.save(<-collection, to: SherpaItems.CollectionStoragePath)

    // create a public capability for the collection
    account.link<&SherpaItems.Collection{NonFungibleToken.CollectionPublic, SherpaItems.SherpaItemsCollectionPublic}>(SherpaItems.CollectionPublicPath, target: SherpaItems.CollectionStoragePath)

    return collectionRef
}

transaction(listingResourceID: UInt64, storefrontAddress: Address) {

    let paymentVault: @FungibleToken.Vault
    let sherpaItemsCollection: &SherpaItems.Collection{NonFungibleToken.Receiver}
    let storefront: &NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}
    let listing: &NFTStorefront.Listing{NFTStorefront.ListingPublic}

    prepare(account: AuthAccount) {
        self.storefront = getAccount(storefrontAddress)
            .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(
                NFTStorefront.StorefrontPublicPath
            )!
            .borrow()
            ?? panic("Could not borrow Storefront from provided address")

        self.listing = self.storefront.borrowListing(listingResourceID: listingResourceID)
            ?? panic("No Listing with that ID in Storefront")
        
        let price = self.listing.getDetails().salePrice

        let mainFLOWVault = account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Cannot borrow FLOW vault from account storage")
        
        self.paymentVault <- mainFLOWVault.withdraw(amount: price)

        self.sherpaItemsCollection = getOrCreateCollection(account: account)
    }

    execute {
        let item <- self.listing.purchase(
            payment: <-self.paymentVault
        )

        self.sherpaItemsCollection.deposit(token: <-item)

        self.storefront.cleanup(listingResourceID: listingResourceID)
    }
}
