/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Utility functions and type extensions used throughout the projects.
*/

import Foundation
import ARKit

// MARK: - float4x4 extensions

extension float4x4 {
    /**
     Treats matrix as a (right-hand column-major convention) transform matrix
     and factors out the translation component of the transform.
    */
    var translation: float3 {
        let translation = columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

// MARK: - CGPoint extensions

extension CGPoint {
    /// Extracts the screen space point from a vector returned by SCNView.projectPoint(_:).
	init(_ vector: SCNVector3) {
		x = CGFloat(vector.x)
		y = CGFloat(vector.y)
	}

    /// Returns the length of a point when considered as a vector. (Used with gesture recognizers.)
    var length: CGFloat {
		return sqrt(x * x + y * y)
	}
}

// String MD5

extension Int
{
    func hexedString() -> String
    {
        return NSString(format:"%02x", self) as String
    }
}

extension NSData
{
    func hexedString() -> String
    {
        var string = String()
        let unsafePointer = bytes.assumingMemoryBound(to: UInt8.self)
        for i in UnsafeBufferPointer<UInt8>(start:unsafePointer, count: length)
        {
            string += Int(i).hexedString()
        }
        return string
    }
    func MD5() -> NSData
    {
        let result = NSMutableData(length: Int(CC_MD5_DIGEST_LENGTH))!
        let unsafePointer = result.mutableBytes.assumingMemoryBound(to: UInt8.self)
        CC_MD5(bytes, CC_LONG(length), UnsafeMutablePointer<UInt8>(unsafePointer))
        return NSData(data: result as Data)
    }
}

extension String
{
    func MD5() -> String
    {
        let data = (self as NSString).data(using: String.Encoding.utf8.rawValue)! as NSData
        return data.MD5().hexedString()
    }
}

//
func findModelFile(docUrl: String) -> String? {
    let enDocUrl = docUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    let localFileUrl = URL.init(string: enDocUrl!)
    // 深度遍历，会递归遍历子文件夹（但不会递归符号链接）
    let fileEnumerator = FileManager().enumerator(at: localFileUrl!, includingPropertiesForKeys: [])!
    // 深度遍历,会递归遍历子文件夹,但效率比较低
    for element in fileEnumerator.allObjects {
        let url = element as! URL
        if url.pathExtension == "scn" || url.pathExtension == "obj" || url.pathExtension == "dae" {
            return url.absoluteString
        } else if url.pathExtension == "DAE" {
            let urlString = url.absoluteString;
            ReplayKitUtil.excuteCmd(urlString);
            return urlString;
        }
    }
//    // 深度遍历，会递归遍历子文件夹 (文件名或者文件夹名可以带有特殊符号的)
//    let enDocUrl = docUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
//    let subPaths = FileManager().subpaths(atPath: enDocUrl!)
//    if (subPaths != nil) {
//        for element in subPaths! {
//            let url = URL.init(string: element)
//            if url?.pathExtension == "scn" || url?.pathExtension == "obj" || url?.pathExtension == "dae" {
//                return url?.absoluteString
//            }
//        }
//    }
    return nil
}
