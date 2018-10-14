//
//  ViewController.swift
//  Test7
//
//  Created by tianqi on 2018/10/14.
//  Copyright © 2018年 tianqi. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        test_C()
        
        test_FMDB()
        
        test_SQLiteDB()
        print("ok")
    }
    
    
    ///
    /// 测试 原生C接口
    ///
    func test_C() {
        let path = Bundle.main.path(forResource: "s1", ofType: "sqlite")!
//        let fileURL = URL(fileURLWithPath: path)
        
        var db: OpaquePointer? = nil
        let r = sqlite3_open(path, &db)
        guard r == SQLITE_OK else {
            print("Unable to open database")
            return
        }
        
        // 初始化 spatialite
        let conn = spatialite_alloc_connection()

//        spatialite_init(1) // 错误，不再使用
        spatialite_init_ex(db, conn, 1)
        
        //定义游标对象
        var stmt : OpaquePointer? = nil
        
        let sql = "SELECT asText(geometry) geometry FROM suzhou"
        let cSQL = sql.cString(using: String.Encoding.utf8)
        let errmsg : UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>? = nil
        if sqlite3_prepare_v2(db, cSQL, -1, &stmt, nil) == SQLITE_OK {
            //准备好之后进行解析
            var queryDataArrM = [[String : AnyObject]]()
            while sqlite3_step(stmt) == SQLITE_ROW {
                //1.获取 解析到的列(字段个数)
                let columnCount = sqlite3_column_count(stmt)
                var dict = [String : AnyObject]()
                for i in 0..<columnCount {
                    // 取出i位置列的字段名,作为字典的键key
                    let cKey = sqlite3_column_name(stmt, i)
                    let key : String = String(validatingUTF8: cKey!)!
                    
                    //取出i位置存储的值,作为字典的值value
                    let cValue = sqlite3_column_text(stmt, i)
                    let value = String(cString:cValue!)
                    dict[key] = value as AnyObject
                    
                }
            }
        }
    }
    
    ///
    /// 测试 FMDB 工具
    ///
    func test_FMDB() {
        let path = Bundle.main.path(forResource: "s1", ofType: "sqlite");
        let fileURL = URL(fileURLWithPath: path!)
        
        let database = FMDatabase(url: fileURL)
        
        guard database.open() else {
            print("Unable to open database")
            return
        }
        
        // 初始化 spatialite
        let conn = spatialite_alloc_connection()
        spatialite_init_ex(OpaquePointer(database.sqliteHandle), conn, 1)
        
        // 上面的 spatialite 可以完成，但是下面的查询就失败了???
        
        // 查询
        do {
            let rs = try database.executeQuery("SELECT asText(geometry) geometry FROM suzhou", values: nil)
            while rs.next() {
                if let x = rs.string(forColumn: "geometry") {
                    print("geometry = \(x);")
                }
            }
            
//            let rs = try database.executeQuery("SELECT  name, name geometry FROM suzhou", values: nil)
//            while rs.next() {
//                if let x = rs.string(forColumn: "name"), let y = rs.string(forColumn: "geometry") {
//                    print("name = \(x); geometry = \(y);")
//                }
//            }
        } catch {
            print("failed: \(error.localizedDescription)")
        }
        
        database.close()
    }
    
    ///
    /// 测试 SQLiteDB 工具
    ///
    func test_SQLiteDB() {
        let path = Bundle.main.path(forResource: "s1", ofType: "sqlite")!
//        let fileURL = URL(fileURLWithPath: path)
        
        let db = SQLiteDB.shared
        let res = db.open(dbPath: path, copyFile: false)
        if !res {
            print("数据库打开失败！")
            return
        }
        
        // 初始化 spatialite
        let conn = spatialite_alloc_connection()
        spatialite_init_ex(db.db, conn, 1)
        
        // 查询
        let data = db.query(sql: "SELECT asText(geometry) geometry FROM suzhou")
        let row = data[0]
        if let name = row["geometry"] {
            print(name)
        }
        
        db.closeDB()
    }
}

