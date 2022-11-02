//
//  UsefulFunctions.swift
//  Pipe-Sequence
//
//  Created by Donghyun LEE on 2022/11/02.
//

import Foundation


func timeToString() -> String {
    let date = Date()
    let calendar = Calendar.current
    let year = calendar.component(.year, from: date)
    let month = calendar.component(.month, from: date)
    let day = calendar.component(.day, from: date)
    let hour = calendar.component(.hour, from: date)
    let minute = calendar.component(.minute, from: date)
    let sec = calendar.component(.second, from: date)
    return String(format:"%04d-%02d-%02d %02d:%02d:%02d in PST", year, month, day, hour, minute, sec)
}
