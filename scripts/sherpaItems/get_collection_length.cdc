import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import SherpaItems from "../../contracts/SherpaItems.cdc"

// This script returns the size of an account's SherpaItems collection.

pub fun main(address: Address): Int {
    let account = getAccount(address)

    let collectionRef = account.getCapability(SherpaItems.CollectionPublicPath)!
        .borrow<&{NonFungibleToken.CollectionPublic}>()
        ?? panic("Could not borrow capability from public collection")
    
    return collectionRef.getIDs().length
}
