//
//  kuzu-swift
//  https://github.com/kuzudb/kuzu-swift
//
//  Copyright © 2023 - 2025 Kùzu Inc.
//  This code is licensed under MIT license (see LICENSE for details)

import Kuzu
import UIKit

class ResultViewController: UIViewController {
    var db: Database!
    var conn: Connection!
    let tempDirUrl = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(UUID().uuidString)
    var systemConfig: SystemConfig!
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBOutlet weak var textView: UITextView!

    @IBAction func clearText(_ sender: Any) {
        self.textView.text = ""
    }

    func write(_ message: String) {
        print(message)
        DispatchQueue.main.async {
            self.textView.text! += "\n"
            self.textView.text! += message
            self.textView.sizeToFit()
        }
    }

    func initKuzu(bmSize: Int, numThreads: Int) {
        DispatchQueue.global().async(execute: {
            self.write(
                "Initializing kuzu with BM=\(bmSize), threads=\(numThreads)"
            )
            self.systemConfig = SystemConfig(
                bufferPoolSize: UInt64(bmSize),
                maxNumThreads: UInt64(numThreads),
                enableCompression: true,
                readOnly: false,
                autoCheckpoint: true,
                checkpointThreshold: UInt64.max,
            )
            self.db = try! Database(self.tempDirUrl.path, self.systemConfig)
            self.conn = try! Connection(self.db)
            self.write("Initialization done")
            self.write("----------------------------------------")
        })
    }

    func writeExecutionTime(_ result: QueryResult) {
        self.write("Execution time: \(result.getExecutionTime())")
        self.write("----------------------------------------")
    }

    func loadMsMarco() throws {
        DispatchQueue.global().async(execute: {
            do {

                let createTableQuery =
                    "CREATE NODE TABLE doc (ID UINT64, content STRING, PRIMARY KEY (ID));"
                self.write("Executing query: \(createTableQuery)")
                var res = try! self.conn.query(createTableQuery)
                self.write("\(res)")

                let fileURL = Bundle.main.url(
                    forResource: "collection_sample",
                    withExtension: "tsv"
                )!

                let copyQuery =
                    "COPY doc from '\(fileURL.path())' (file_format='csv', delim = '\t');"
                self.write("Executing query: \(copyQuery)")
                res = try self.conn.query(copyQuery)
                self.write("\(res)")
                self.writeExecutionTime(res)
            } catch let error as KuzuError {
                self.write("Query failed: \(error.message)")
            } catch _ {
                self.write("Query failed with unknown error")
            }
        })
    }

    func loadLdbc() throws {
        DispatchQueue.global().async(execute: {
            do {
                let schemaCypherUrl = Bundle.main.url(
                    forResource: "schema",
                    withExtension: "cypher"
                )!
                var schemaCypher: [String] = []
                let schemaCypherStr = try! String(
                    contentsOf: schemaCypherUrl,
                    encoding: .utf8
                )
                schemaCypherStr.split(separator: "\n").forEach {
                    schemaCypher.append(String($0))
                }
                self.write("Creating schema...")
                for cypher in schemaCypher {
                    _ = try self.conn.query(cypher)
                }

                let rootUrl = schemaCypherUrl.deletingLastPathComponent()
                var copyCypher: [String] = []
                let copyCypherUrl = Bundle.main.url(
                    forResource: "copy",
                    withExtension: "cypher"
                )!
                let copyCypherStr = try! String(
                    contentsOf: copyCypherUrl,
                    encoding: .utf8
                )
                copyCypherStr.split(separator: "\n").forEach {
                    let s = String($0).replacingOccurrences(
                        of: "dataset/ldbc-1/csv/",
                        with: rootUrl.path()
                    )
                    copyCypher.append(s)
                }
                var totalCopyTime: Double = 0.0
                self.write("Copying data...")
                for cypher in copyCypher {
                    let res = try self.conn.query(cypher)
                    totalCopyTime += res.getExecutionTime()
                }
                self.write("Total copy time: \(totalCopyTime)")
                self.write("----------------------------------------")
            } catch let error as KuzuError {
                self.write("Query failed: \(error.message)")
            } catch _ {
                self.write("Query failed with unknown error")
            }
        })
    }

    func loadLastFm() throws {
        DispatchQueue.global().async(execute: {
            do {
                let idUrl = Bundle.main.url(
                    forResource: "lastfm_id",
                    withExtension: "npy"
                )!
                let trainUrl = Bundle.main.url(
                    forResource: "lastfm_train",
                    withExtension: "npy"
                )!
                let createTableQuery =
                    "CREATE NODE TABLE tbl (id int64 PRIMARY KEY, vec FLOAT[65]);"
                self.write("Executing query: \(createTableQuery)")
                var res = try self.conn.query(createTableQuery)
                self.write("\(res)")

                let copyQuery =
                    "COPY tbl FROM ('\(idUrl.path())', '\(trainUrl.path())') BY COLUMN;"
                self.write("Executing query: \(copyQuery)")
                res = try self.conn.query(copyQuery)
                self.write("\(res)")
                self.writeExecutionTime(res)
            } catch let error as KuzuError {
                self.write("Query failed: \(error.message)")
            } catch _ {
                self.write("Query failed with unknown error")
            }
        })
    }

    func loadMnist() throws {
        DispatchQueue.global().async(execute: {
            do {
                self.write(
                    "Execution threads: \(self.conn.getMaxNumThreadForExec())"
                )
                let fileURL = Bundle.main.url(
                    forResource: "mnist",
                    withExtension: "parquet"
                )!
                let createTableQuery =
                    "CREATE NODE TABLE tbl (id int64 PRIMARY KEY, vec FLOAT[784]);"
                self.write("Executing query: \(createTableQuery)")
                var res = try self.conn.query(createTableQuery)
                self.write("\(res)")

                let copyQuery = "COPY tbl FROM '\(fileURL.path())'"
                self.write("Executing query: \(copyQuery)")
                res = try self.conn.query(copyQuery)
                self.write("\(res)")
                self.writeExecutionTime(res)
            } catch let error as KuzuError {
                self.write("Query failed: \(error.message)")
            } catch _ {
                self.write("Query failed with unknown error")
            }
        })
    }

    func runFts() throws {
        DispatchQueue.global().async(execute: {
            let createIndexQuery =
                "CALL CREATE_FTS_INDEX('doc', 'contentIdx', ['content']);"
            self.write("Executing query: \(createIndexQuery)")
            var res = try! self.conn.query(createIndexQuery)
            self.writeExecutionTime(res)

            self.conn.setMaxNumThreadForExec(1)

            let query1 =
                "CALL query_fts_index('doc', 'contentIdx', 'dispossessed meaning') RETURN score LIMIT 10;"
            self.write("Executing query: \(query1)")
            res = try! self.conn.query(query1)
            self.write("\(res)")
            self.writeExecutionTime(res)

            let query2 =
                "CALL query_fts_index('doc', 'contentIdx', 'define extreme') RETURN score LIMIT 10;"
            self.write("Executing query: \(query2)")
            res = try! self.conn.query(query2)
            self.write("\(res)")
            self.writeExecutionTime(res)

        })
    }

    func runLdbc() throws {
        DispatchQueue.global().async(execute: {
            let queries = [
                "match (c:comment) where c.creationDate<='2011-01-01' return count(*);",
                "match (p:person)-[e1:likeComment]->(c1:Comment), (p)-[e2:likeComment]->(c2:comment) where p.lastName='Kelly' return count(*);",
                "match p=(n1:person)-[e:knows* all SHORTEST]->(n2:person) where n1.firstName='Igor' and n1.lastName='Kofler' and n1.birthday='1983-08-25' return length(p), count(*);",
                "match (c:comment) return min(c.creationDate), max(c.creationDate), min(c.locationIP), max(c.locationIP), min(c.browserUsed), max(c.browserUsed);",
                "match (c:comment) return c.browserUsed, min(c.creationDate), max(c.creationDate);",
                "match (c:comment) return distinct c.browserUsed;",
                "match (c:comment) return c.* order by c.creationDate limit 100;",
            ]
            for query in queries {
                self.write("Executing query: \(query)")
                let warmUpRes = try! self.conn.query(query)
                self.write("\(warmUpRes)")
                _ = try! self.conn.query(query)
                var averageTime: Double = 0.0
                var averageCompileTime: Double = 0.0
                let runs: Int = 5
                for _ in 0..<runs {
                    let res = try! self.conn.query(query)
                    averageTime += res.getExecutionTime()
                    averageCompileTime += res.getCompilingTime()
                }
                averageTime /= Double(runs)
                averageCompileTime /= Double(runs)
                self.write("Average exec time: \(averageTime)")
                self.write("Average compile time: \(averageCompileTime)")
                self.write("----------------------------------------")
            }
            let commentUrl = Bundle.main.url(
                forResource: "comment_0_0",
                withExtension: "csv"
            )!

            var commentId: Int64 = 2_200_000_000_000
            let csvChunk = try! self.readCSVChunk(
                from: commentUrl,
                skip: 100_000,
                limit: 10_000
            )
            var params: [[String: Any]] = []
            for row in csvChunk {
                var param: [String: Any] = [:]
                let splited = row.split(separator: "|")
                let timestampStr = String(splited[1])
                let locationIP = String(splited[2])
                let browserUsed = String(splited[3])
                let content = String(splited[4])
                let lengthStr = String(splited[5])
                let length: Int64 = Int64(lengthStr)!
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                formatter.locale = Locale(identifier: "en_US_POSIX")  // important for fixed-format dates

                let timestamp = formatter.date(from: timestampStr)!
                param["ID"] = commentId
                commentId += 1
                param["creationDate"] = timestamp
                param["locationIP"] = locationIP
                param["browserUsed"] = browserUsed
                param["content"] = content
                param["length"] = length
                params.append(param)
            }
            let insertQuery =
                "CREATE (c:Comment {ID: $ID, creationDate: $creationDate, locationIP:$locationIP, browserUsed:$browserUsed, content:$content, length:$length});"
            let preparedStatement = try! self.conn.prepare(insertQuery)
            self.write("Inserting 10K tuples")
            var totalInsertTime: Double = 0
            var totalInsertCompileTime: Double = 0
            for param in params {
                let res = try! self.conn.execute(preparedStatement, param)
                totalInsertCompileTime += res.getCompilingTime()
                totalInsertTime += res.getExecutionTime()
            }
            self.write("Total exec time: \(totalInsertTime)")
            self.write("Total compile time: \(totalInsertCompileTime)")
            self.write("----------------------------------------")

            self.write("CHECKPOINT")
            let res = try! self.conn.query("CHECKPOINT")
            self.writeExecutionTime(res)
        })
    }

    func runLastFm() throws {
        DispatchQueue.global().async(execute: {
            let createIndexQuery =
                "CALL CREATE_VECTOR_INDEX('tbl', 'vec_idx', 'vec', metric := 'cosine')"
            self.write("Executing query: \(createIndexQuery)")
            var res = try! self.conn.query(createIndexQuery)
            self.write("\(res)")
            self.writeExecutionTime(res)

            let searchQuery =
                "CALL QUERY_VECTOR_INDEX('tbl', 'vec_idx', $queryVector, 5) RETURN node.id ORDER BY distance;"
            self.write("Preparing query: \(searchQuery)")
            let preparedStatement = try! self.conn.prepare(searchQuery)

            let insertQuery =
                "CREATE (n:tbl {id: $id, vec: $vec})"
            self.write(
                "Preparing query: \(insertQuery)"
            )
            let preparedInsertStatement = try! self.conn.prepare(insertQuery)

            self.write("Executing query with qvec1")
            res = try! self.conn.execute(
                preparedStatement,
                ["queryVector": lastfm_qvec1]
            )
            self.write("\(res)")
            self.writeExecutionTime(res)

            self.write("Executing query with qvec2")
            res = try! self.conn.execute(
                preparedStatement,
                ["queryVector": lastfm_qvec2]
            )
            self.write("\(res)")
            self.writeExecutionTime(res)

            self.write("Executing query with qvec3")
            res = try! self.conn.execute(
                preparedStatement,
                ["queryVector": lastfm_qvec3]
            )
            self.write("\(res)")
            self.writeExecutionTime(res)

            self.write("Executing query with qvec4")
            res = try! self.conn.execute(
                preparedStatement,
                ["queryVector": lastfm_qvec4]
            )
            self.write("\(res)")
            self.writeExecutionTime(res)

            self.write("Executing query with qvec5")
            res = try! self.conn.execute(
                preparedStatement,
                ["queryVector": lastfm_qvec5]
            )
            self.write("\(res)")
            self.writeExecutionTime(res)

            self.write("Executing query with qvec6")
            res = try! self.conn.execute(
                preparedStatement,
                ["queryVector": lastfm_qvec6]
            )
            self.write("\(res)")
            self.writeExecutionTime(res)

            var insertionId = 1_000_000

            var totalExecTime: Double = 0.0
            var totalCompileTime: Double = 0.0
            self.write("Executing insertions")
            for vec in lastfm_insert {
                let param: [String: Any] = ["id": insertionId, "vec": vec]
                res = try! self.conn.execute(
                    preparedInsertStatement,
                    param
                )
                totalExecTime += res.getExecutionTime()
                totalCompileTime += res.getCompilingTime()
                insertionId += 1
            }
            self.write("Total execution time: \(totalExecTime)")
            self.write("Total compile time: \(totalCompileTime)")

            self.write("CHECKPOINT")
            res = try! self.conn.query("CHECKPOINT")
            self.write("\(res)")
            self.writeExecutionTime(res)
        })
    }

    func runMnist() throws {
        DispatchQueue.global().async(execute: {
            let createIndexQuery =
                "CALL CREATE_VECTOR_INDEX('tbl', 'vec_idx', 'vec', metric := 'l2')"
            self.write("Executing query: \(createIndexQuery)")
            var res = try! self.conn.query(createIndexQuery)
            self.write("\(res)")
            self.writeExecutionTime(res)

            let searchQuery =
                "CALL QUERY_VECTOR_INDEX('tbl', 'vec_idx', $queryVector, 5) RETURN node.id ORDER BY distance;"
            self.write("Preparing query: \(searchQuery)")
            let preparedStatement = try! self.conn.prepare(searchQuery)

            let insertQuery =
                "CREATE (n:tbl {id: $id, vec: $vec})"
            self.write(
                "Preparing query: \(insertQuery)"
            )
            let preparedInsertStatement = try! self.conn.prepare(insertQuery)

            self.write("Executing query with qvec1")
            res = try! self.conn.execute(
                preparedStatement,
                ["queryVector": mnist_qvec1]
            )
            self.write("\(res)")
            self.writeExecutionTime(res)

            self.write("Executing query with qvec2")
            res = try! self.conn.execute(
                preparedStatement,
                ["queryVector": mnist_qvec2]
            )
            self.write("\(res)")
            self.writeExecutionTime(res)

            self.write("Executing query with qvec3")
            res = try! self.conn.execute(
                preparedStatement,
                ["queryVector": mnist_qvec3]
            )
            self.write("\(res)")
            self.writeExecutionTime(res)

            self.write("Executing query with qvec4")
            res = try! self.conn.execute(
                preparedStatement,
                ["queryVector": mnist_qvec4]
            )
            self.write("\(res)")
            self.writeExecutionTime(res)

            self.write("Executing query with qvec5")
            res = try! self.conn.execute(
                preparedStatement,
                ["queryVector": mnist_qvec5]
            )
            self.write("\(res)")
            self.writeExecutionTime(res)

            self.write("Executing query with qvec6")
            res = try! self.conn.execute(
                preparedStatement,
                ["queryVector": mnist_qvec6]
            )
            self.write("\(res)")
            self.writeExecutionTime(res)

            var insertionId = 1_000_000
            var totalExecTime: Double = 0.0
            var totalCompileTime: Double = 0.0
            self.write("Executing insertions")
            for vec in mnist_insert {
                let param: [String: Any] = ["id": insertionId, "vec": vec]
                res = try! self.conn.execute(
                    preparedInsertStatement,
                    param
                )
                totalExecTime += res.getExecutionTime()
                totalCompileTime += res.getCompilingTime()
                insertionId += 1
            }
            self.write("Total execution time: \(totalExecTime)")
            self.write("Total compile time: \(totalCompileTime)")

            self.write("CHECKPOINT")
            res = try! self.conn.query("CHECKPOINT")
            self.write("\(res)")
            self.writeExecutionTime(res)
        })
    }

    func readCSVChunk(from fileURL: URL, skip: Int, limit: Int) throws
        -> [String]
    {
        guard let stream = InputStream(url: fileURL) else {
            throw NSError(
                domain: "CSVReader",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Unable to open file"]
            )
        }

        stream.open()
        defer { stream.close() }

        var lines: [String] = []
        let bufferSize = 4096
        var buffer = Data()
        var skipped = 0
        var collected = 0
        var temp = [UInt8](repeating: 0, count: bufferSize)

        while stream.hasBytesAvailable {
            let read = stream.read(&temp, maxLength: bufferSize)
            if read > 0 {
                buffer.append(temp, count: read)

                while let range = buffer.range(of: Data([UInt8(ascii: "\n")])) {
                    let lineData = buffer.subdata(in: 0..<range.lowerBound)
                    buffer.removeSubrange(0...range.upperBound - 1)

                    if let line = String(data: lineData, encoding: .utf8) {
                        if skipped < skip {
                            skipped += 1
                        } else if collected < limit {
                            lines.append(line)
                            collected += 1
                        } else {
                            return lines
                        }
                    }
                }
            } else {
                break
            }
        }

        return lines
    }

    func executeQuery(query: String) throws {
        DispatchQueue.global().async(execute: {
            self.write("Executing query: \(query)")
            do {
                let res = try self.conn.query(query)
                self.write("\(res)")
                self.writeExecutionTime(res)
            } catch let error as KuzuError {
                self.write("Query failed: \(error.message)")
            } catch _ {
                self.write("Query failed with unknown error")
            }
        })
    }
}
