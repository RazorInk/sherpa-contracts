import SherpaItems from "../../contracts/SherpaItems.cdc"

// This scripts returns the number of SherpaItems currently in existence.

pub fun main(): UInt64 {    
    return SherpaItems.totalSupply
}
