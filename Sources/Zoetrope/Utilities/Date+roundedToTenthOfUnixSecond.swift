//
//  File.swift
//  
//
//  Created by Dale Price on 7/2/24.
//

import Foundation

internal extension Date {
	var roundedToUnixTenthOfSecond: Date {
		let tenths = (self.timeIntervalSince1970 * 10).rounded()
		return .init(timeIntervalSince1970: Double(tenths) / 10.0)
	}
}
