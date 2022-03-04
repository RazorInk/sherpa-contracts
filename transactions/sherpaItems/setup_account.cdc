import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import SherpaItems from "../../contracts/SherpaItems.cdc"

// This transaction configures an account to hold Sherpa Items.

transaction {
    prepare(signer: AuthAccount) {
        // if the account doesn't already have a collection
        if signer.borrow<&SherpaItems.Collection>(from: SherpaItems.CollectionStoragePath) == nil {

            // create a new empty collection
            let collection <- SherpaItems.createEmptyCollection()
            
            // save it to the account
            signer.save(<-collection, to: SherpaItems.CollectionStoragePath)

            // create a public capability for the collection
            signer.link<&SherpaItems.Collection{NonFungibleToken.CollectionPublic, SherpaItems.SherpaItemsCollectionPublic}>(SherpaItems.CollectionPublicPath, target: SherpaItems.CollectionStoragePath)
        }
    }
}
