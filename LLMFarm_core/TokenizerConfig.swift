
import Foundation

/**
    TokenizerConfig is a struct that contains the URLs to the vocab.json and merges.txt files in the bundle.
    - Parameters:
        - vocab: resource URL to vocab.json file in the bundle (e.g. Bundle.module.url(forResource: "vocab", withExtension: "json")!)
        - merges: resource URL to merges.txt file in the bundle (e.g. Bundle.module.url(forResource: "merges", withExtension: "txt")!)
*/
struct TokenizerConfig {
    let vocab: URL
    let merges: URL
}
