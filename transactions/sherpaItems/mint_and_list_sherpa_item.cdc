import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import SherpaItems from "../../contracts/SherpaItems.cdc"
import FungibleToken from "../../contracts/FungibleToken.cdc"
import FlowToken from "../../contracts/FlowToken.cdc"
import NFTStorefront from "../../contracts/NFTStorefront.cdc"

// This transction uses the NFTMinter resource to mint a new NFT.

transaction(recipient: Address, kind: UInt8, rarity: UInt8) {

    // local variable for storing the minter reference
    let minter: &SherpaItems.NFTMinter
    let flowReceiver: Capability<&FlowToken.Vault{FungibleToken.Receiver}>
    let sherpaItemsProvider: Capability<&SherpaItems.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
    let storefront: &NFTStorefront.Storefront

    prepare(signer: AuthAccount) {

        // borrow a reference to the NFTMinter resource in storage
        self.minter = signer.borrow<&SherpaItems.NFTMinter>(from: SherpaItems.MinterStoragePath)
            ?? panic("Could not borrow a reference to the NFT minter")

         // We need a provider capability, but one is not provided by default so we create one if needed.
        let sherpaItemsCollectionProviderPrivatePath = /private/sherpaItemsCollectionProvider

        self.flowReceiver = signer.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver)!

        assert(self.flowReceiver.borrow() != nil, message: "Missing or mis-typed FLOW receiver")

        if !signer.getCapability<&SherpaItems.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(sherpaItemsCollectionProviderPrivatePath)!.check() {
            signer.link<&SherpaItems.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(sherpaItemsCollectionProviderPrivatePath, target: SherpaItems.CollectionStoragePath)
        }

        self.sherpaItemsProvider = signer.getCapability<&SherpaItems.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(sherpaItemsCollectionProviderPrivatePath)!

        assert(self.sherpaItemsProvider.borrow() != nil, message: "Missing or mis-typed SherpaItems.Collection provider")

        self.storefront = signer.borrow<&NFTStorefront.Storefront>(from: NFTStorefront.StorefrontStoragePath)
            ?? panic("Missing or mis-typed NFTStorefront Storefront")
    }

    execute {
        // get the public account object for the recipient
        let recipient = getAccount(recipient)

        // borrow the recipient's public NFT collection reference
        let receiver = recipient
            .getCapability(SherpaItems.CollectionPublicPath)!
            .borrow<&{NonFungibleToken.CollectionPublic}>()
            ?? panic("Could not get receiver reference to the NFT Collection")

        // mint the NFT and deposit it to the recipient's collection
        let kindValue = SherpaItems.Kind(rawValue: kind) ?? panic("invalid kind")
        let rarityValue = SherpaItems.Rarity(rawValue: rarity) ?? panic("invalid rarity")

        // mint the NFT and deposit it to the recipient's collection
        self.minter.mintNFT(
            recipient: receiver,
            kind: kindValue,
            rarity: rarityValue,
        )

        let saleCut = NFTStorefront.SaleCut(
            receiver: self.flowReceiver,
            amount: SherpaItems.getItemPrice(rarity: rarityValue)
        )
        
        self.storefront.createListing(
            nftProviderCapability: self.sherpaItemsProvider,
            nftType: Type<@SherpaItems.NFT>(),
            nftID: SherpaItems.totalSupply - 1,
            salePaymentVaultType: Type<@FlowToken.Vault>(),
            saleCuts: [saleCut]
        )
    }
}
