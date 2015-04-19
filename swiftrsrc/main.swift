//
//  main.swift
//  swiftrsrc
//
//  Created by Indragie on 1/25/15.
//  Copyright (c) 2015 Indragie Karunaratne. All rights reserved.
//

import Foundation

func main() {
    let registry = CommandRegistry()
    registry.register(GenerateCommand())
    let helpCommand = HelpCommand(registry: registry)
    registry.register(helpCommand)
    
    registry.main(defaultCommand: helpCommand) { error in
        fputs("\(error.toNSError().localizedDescription)\n", stderr)
    }
}

main()
