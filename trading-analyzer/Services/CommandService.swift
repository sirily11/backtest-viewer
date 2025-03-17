//
//  CommandService.swift
//  trading-analyzer
//
//  Created by Qiwei Li on 3/17/25.
//

import SwiftUI

enum CommandError: LocalizedError {
    case commandFailed(reason: String)
    case processFailed(reason: String)

    var errorDescription: String? {
        switch self {
        case .commandFailed(let reason):
            return "Command failed: \(reason)"
        case .processFailed(let reason):
            return "Process failed: \(reason)"
        }
    }
}

enum CommandStatus: Equatable {
    case notRunning
    case running(output: String?)
    case success
    case failure(error: Error)

    var isRunning: Bool {
        switch self {
        case .running:
            return true
        default:
            return false
        }
    }

    static func == (lhs: CommandStatus, rhs: CommandStatus) -> Bool {
        switch (lhs, rhs) {
        case (.notRunning, .notRunning):
            return true
        case (.running(let output1), .running(let output2)):
            return output1 == output2
        case (.success, .success):
            return true
        case (.failure, .failure):
            return true
        default:
            return false
        }
    }
}

@Observable
class CommandService {
    private(set) var speedupStatus: CommandStatus = .notRunning
    private(set) var runBacktestStatus: CommandStatus = .notRunning

    /**
     Run a shell command as an async sequence that yields output as it becomes available.

     - Parameters:
        - command: The shell command to execute
        - workingDirectory: The directory to run the command in (optional)
        - environment: Environment variables to set for the command (optional)

     - Returns: An AsyncThrowingStream that yields command output and throws CommandError on failure
     */
    func runCommand(
        command: String,
        workingDirectory: URL? = nil,
        environment: [String: String]? = nil
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            // Create a process
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-l", "-c", command]

            print("Executing command: \(command)")

            // Set working directory if provided
            if let workingDirectory = workingDirectory {
                process.currentDirectoryPath = workingDirectory.path
                print("Working directory: \(workingDirectory.path)")
            }

            // Set environment variables if provided
            if let environment = environment {
                var processEnvironment = ProcessInfo.processInfo.environment
                for (key, value) in environment {
                    processEnvironment[key] = value
                    print("Setting environment variable: \(key)=\(value)")
                }
                process.environment = processEnvironment
            } else {
                // Always use the current process environment
                process.environment = ProcessInfo.processInfo.environment
            }

            // Set up pipes to capture output and errors
            let pipe = Pipe()
            process.standardError = pipe

            let handler = pipe.fileHandleForReading

            // Buffer for accumulated error output
            var errorOutput = ""

            handler.readabilityHandler = { handle in
                let data = handle.availableData
                if data.count > 0 {
                    if let output = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            continuation.yield(output)
                            errorOutput += output
                        }
                    }
                }
            }

            // Start the process
            do {
                try process.run()

                // Handle process completion in a background queue
                DispatchQueue.global().async {
                    process.waitUntilExit()

                    // Clean up readability handlers
                    handler.readabilityHandler = nil

                    // Check the exit status
                    print("Process exited with status: \(process.terminationStatus)")
                    if process.terminationStatus != 0 {
                        if !errorOutput.isEmpty {
                            continuation.finish(
                                throwing: CommandError.commandFailed(
                                    reason:
                                    "Command failed with exit code \(process.terminationStatus): \(errorOutput)"
                                ))
                        } else {
                            continuation.finish(
                                throwing: CommandError.commandFailed(
                                    reason:
                                    "Command failed with exit code \(process.terminationStatus)"
                                ))
                        }
                    } else {
                        continuation.finish()
                    }
                }
            } catch {
                handler.readabilityHandler = nil

                continuation.finish(
                    throwing: CommandError.processFailed(reason: error.localizedDescription))
            }
        }
    }

    /**
     Run make command
     */
    func runMakeCommand(makeFilePath: URL, goBinaryPath: URL) async throws {
        runBacktestStatus = .running(output: "Running make command")
        let cwd = makeFilePath.deletingLastPathComponent()
        let makeCommand = "make -f \(makeFilePath.path) build"

        do {
            for try await output in runCommand(
                command: makeCommand,
                workingDirectory: cwd,
                environment: ["GO": goBinaryPath.path]
            ) {
                runBacktestStatus = .running(output: output)
            }
            runBacktestStatus = .success
        } catch let error as CommandError {
            runBacktestStatus = .failure(error: error)
            throw error
        } catch {
            let commandError = CommandError.processFailed(reason: error.localizedDescription)
            runBacktestStatus = .failure(error: commandError)
            throw commandError
        }
    }

    /**
     Run back test command.
     */
    func runBacktestCommand(
        resultFilePath: URL,
        dataFilePath: URL,
        taskFilePath: URL,
        strategyFilePath: URL,
        executableFilePath: URL
    ) async throws {
        runBacktestStatus = .running(output: "Running backtest command")

        // empty result folder
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: resultFilePath)
            try fileManager.createDirectory(
                at: resultFilePath, withIntermediateDirectories: true, attributes: nil
            )
        } catch {
            throw CommandError.commandFailed(
                reason: "Failed to empty result folder: \(error.localizedDescription)")
        }

        // Construct the command
        let command = """
        \(executableFilePath.path) trade backtest from-swap-parquet \
         --save-result-as-csv \
        --result-dir "\(resultFilePath.path)" \
        --parquet-file-path-pattern "\(dataFilePath.path)/.*.parquet" \
        --task-json-file-path-pattern "\(taskFilePath.path)/.*.json" \
         --speedup-helper-data-file-path \(dataFilePath.appending(component: "speedup-helper-data.json").path) \
        --trade-strategy-plugin-file-path-pattern "\(strategyFilePath.path)/.*.so"
        """

        do {
            for try await output in runCommand(command: command) {
                runBacktestStatus = .running(output: output)
            }
            runBacktestStatus = .success
        } catch let error as CommandError {
            runBacktestStatus = .failure(error: error)
            throw error
        } catch {
            let commandError = CommandError.processFailed(reason: error.localizedDescription)
            runBacktestStatus = .failure(error: commandError)
            throw commandError
        }
    }

    func runGenerateSpeedupHelperDataCommand(
        executablePath: URL,
        dataFilePath: URL
    ) async throws {
        speedupStatus = .running(output: nil)
        // Construct the command
        let command = """
        \(executablePath.path) trade backtest generate-speedup-helper-data-from-swap-parquet \\
         --belong-chain solana \\
        --market-type p2r \\
        --output-file-path "\(dataFilePath.appending(component: "speedup-helper-data.json").path)" \\
        --parquet-file-path-pattern "\(dataFilePath.path)/.*.parquet"
        """

        do {
            for try await output in runCommand(command: command) {
                speedupStatus = .running(output: output)
            }
            speedupStatus = .success
        } catch let error as CommandError {
            speedupStatus = .failure(error: error)
            throw error
        } catch {
            let commandError = CommandError.processFailed(reason: error.localizedDescription)
            speedupStatus = .failure(error: commandError)
            throw commandError
        }
    }

    func getGoPath() throws -> String {
        let command = "go env GOPATH"

        // Create a process
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", command]

        // Set the environment variables - this is the key fix
        process.environment = ProcessInfo.processInfo.environment

        // Set up pipes for output
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()

            // Get the data from the output pipe
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

            // Convert data to string
            guard let output = String(data: outputData, encoding: .utf8) else {
                throw CommandError.commandFailed(reason: "Could not decode output")
            }

            // Check if there was an error
            if let error = String(data: errorData, encoding: .utf8), !error.isEmpty {
                throw CommandError.commandFailed(reason: error)
            }

            // Trim whitespace and return
            let trimmedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmedOutput.isEmpty {
                throw CommandError.commandFailed(reason: "Empty output from go command")
            }

            return trimmedOutput
        } catch let processError as NSError {
            throw CommandError.processFailed(reason: processError.localizedDescription)
        }
    }
}
