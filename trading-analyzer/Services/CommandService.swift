//
//  CommandService.swift
//  trading-analyzer
//
//  Created by Qiwei Li on 3/17/25.
//

import SwiftUI

enum CommandError: Error {
    case commandFailed(reason: String)
    case processFailed(reason: String)
}

@Observable
class CommandService {
    private(set) var isRunning: Bool = false
    
    /**
     Run make command
     */
    func runMakeCommand(makeFilePath: String) throws -> Void {
        // Create a process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/make")
        process.arguments = ["-f", makeFilePath]
        
        // Set up pipes to capture output and errors
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            // Start the process
            try process.run()
            
            // Read the error output
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
            
            // Wait for the process to complete
            process.waitUntilExit()
            
            // Check the exit status
            if process.terminationStatus != 0 {
                // If there's error output, include it in the error
                if !errorOutput.isEmpty {
                    throw CommandError.commandFailed(reason: "Make command failed with exit code \(process.terminationStatus): \(errorOutput)")
                } else {
                    throw CommandError.commandFailed(reason: "Make command failed with exit code \(process.terminationStatus)")
                }
            }
        } catch let error as CommandError {
            // Re-throw CommandError instances
            throw error
        } catch {
            // For any other errors (like process.run() failing), throw the processFailed error
            throw CommandError.processFailed(reason: error.localizedDescription)
        }
    }
    
    /**
     Run back test command.
     */
    func runBacktestCommand(
        resultFilePath: String,
        dataFilePath: String,
        taskFilePath: String,
        strategyFilePath: String,
        executableFilePath: String
    ) throws(CommandError) {
        isRunning = true
        // Construct the command
        let command = """
        \(executableFilePath) trade backtest from-swap-parquet \
         --save-result-as-csv \
        --result-dir "\(resultFilePath)" \
        --parquet-file-path-pattern "\(dataFilePath)/.*.parquet" \
        --task-json-file-path-pattern "\(taskFilePath)/.*.json" \
         --speedup-helper-data-file-path \(dataFilePath) \
        --trade-strategy-plugin-file-path-pattern "\(strategyFilePath)/.*.so"
        """
        
        // Create a process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", command]
        
        // Set up pipes to capture output and errors
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            // Start the process
            try process.run()
            
            // Read the output
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: outputData, encoding: .utf8), !output.isEmpty {
                print("Output: \(output)")
            }
            
            // Read any errors
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            if let error = String(data: errorData, encoding: .utf8), !error.isEmpty {
                throw CommandError.commandFailed(reason: error)
            }
            
            // Wait for the process to complete
            process.waitUntilExit()
            
            // Check the exit status
            if process.terminationStatus == 0 {
                print("Command executed successfully")
            } else {
                print("Command failed with exit code: \(process.terminationStatus)")
            }
        } catch {
            isRunning = false
            throw CommandError.processFailed(reason: error.localizedDescription)
        }
    }
    
    func runGenerateSpeedupHelperDataCommand(
        executablePath: String,
        dataFilePath: String
    ) throws {
        // Construct the command
        let command = """
        \(executablePath) trade backtest generate-speedup-helper-data-from-swap-parquet \\
         --belong-chain solana \\
        --market-type p2r \\
        --output-file-path "\(dataFilePath)" \\
        --parquet-file-path-pattern "\(dataFilePath)/.*.parquet"
        """
        
        // Create a process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", command]
        
        // Set up pipes to capture output and errors
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            // Start the process
            try process.run()
            
            // Read the error output
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
            
            // Wait for the process to complete
            process.waitUntilExit()
            
            // Check the exit status
            if process.terminationStatus != 0 {
                // If there's error output, include it in the error
                if !errorOutput.isEmpty {
                    throw CommandError.commandFailed(reason: "Generate speedup helper data command failed with exit code \(process.terminationStatus): \(errorOutput)")
                } else {
                    throw CommandError.commandFailed(reason: "Generate speedup helper data command failed with exit code \(process.terminationStatus)")
                }
            }
        } catch let error as CommandError {
            // Re-throw CommandError instances
            throw error
        } catch {
            // For any other errors (like process.run() failing), throw the processFailed error
            throw CommandError.processFailed(reason: error.localizedDescription)
        }
    }
}
