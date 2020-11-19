//
//  Board.swift
//  chess
//
//  Created by Hayden Collins on 9/29/20.
//  Copyright © 2020 Hayden Collins. All rights reserved.
//
import Foundation
import Cocoa

class Board {
    var boardDict = [String:BoardSquare]()
    var buttons = [String:NSButton]()
    var legalMoves = Array<String>()
    var whiteTurn = true
    var boardSquareToMove : BoardSquare?
    var originalCord : String!
    var castlingAvailable = false
    var enPassantAvailable = false
    var globalWhiteScore : NSTextField!
    var globalBlackScore : NSTextField!
    var globalMoveCountDisplay : NSTextField!
    var globalCheckMateText : NSTextField!
    var globalwhiteScoreImageViews : Array<NSImageView>!
    var globalblackScoreImageViews : Array<NSImageView>!
    var blackMaterial = Array<Piece>()
    var whiteMaterial = Array<Piece>()
    var moveCount = 1
    var whiteKingLocation = "E1"
    var blackKingLocation = "E8"
    var whiteTotalLegalMoves = Array<String>()
    var blackTotalLegalMoves = Array<String>()
    var movesArr = Array<Move>()
    var tableView : NSTableView!

    //this displays the pieces on the view based on boardDict
    func updateBoardView(buttons: Dictionary<String,NSButton>){
        for l in letters {
            for n in numbers {
                let pieceColor = boardDict[l+n]?.piece.color
                if (boardDict[l+n]?.piece.pieceType == "pawn"){
                    buttons[l+n]!.image = NSImage(named: "pawn_" + pieceColor!)
                }
                if (boardDict[l+n]?.piece.pieceType == "rook"){
                    buttons[l+n]!.image = NSImage(named: "rook_" + pieceColor!)
                }
                if (boardDict[l+n]?.piece.pieceType == "bishop"){
                    buttons[l+n]!.image = NSImage(named: "bishop_" + pieceColor!)
                }
                if (boardDict[l+n]?.piece.pieceType == "knight"){
                    buttons[l+n]!.image = NSImage(named: "knight_" + pieceColor!)
                }
                if (boardDict[l+n]?.piece.pieceType == "king"){
                    buttons[l+n]!.image = NSImage(named: "king_" + pieceColor!)
                }
                if (boardDict[l+n]?.piece.pieceType == "queen"){
                    buttons[l+n]!.image = NSImage(named: "queen_" + pieceColor!)
                }
                if (boardDict[l+n] == nil) {
                    buttons[l+n]?.image = nil
                }
            }
        }
        showMaterialValue(globalWhiteScore: globalWhiteScore, globalBlackScore: globalBlackScore)
    }
    
    func updateBoard(boardSquareLocation: String) {
        recordMove(orginalCord: originalCord, boardSquareLocation: boardSquareLocation)
        //updating boardDict
        boardDict[boardSquareLocation] = boardSquareToMove
        boardDict[originalCord] = nil
        boardSquareToMove?.piece.hasMoved = true
        //saves the legal moves of next turn for the moved piece
        boardDict[boardSquareLocation]?.piece.pieceLegalMoves = getLegalMoves(boardSquareLocation: boardSquareLocation)
        //clearing legal moves
        legalMoves = []
        showLegalMoves(arr: legalMoves)
        updateKingLocation(boardSquareLocation: boardSquareLocation)//if the kings moves, updates position
        updateMaterialValue(boardSquareLocation: boardSquareLocation)
        boardSquareToMove = nil//resetting selected piece to nil
        if promotionAvailable() == true {promoteToQueen(boardSquareLocation: boardSquareLocation)}// if a pawn is on back rank, becomes a quuen
        if whiteTurn == true {whiteTotalLegalMoves = legalMovesOfColor(color: "white"); whiteTurn = false}//sets whites totalMoves and flips turns
        else {blackTotalLegalMoves = legalMovesOfColor(color: "black"); whiteTurn = true; moveCount += 1;         showMoveCount()}//sets blacks totalMoves and flips turns
    }
    
    func boardSquareClicked(boardSquareLocation: String) {//when a button is clicked
        if boardSquareToMove == nil{//if a new piece is selected
            if boardDict[boardSquareLocation]?.piece.color == "white" && whiteTurn == true {
                selectPiece(boardSquareLocation: boardSquareLocation)
            }
            else if boardDict[boardSquareLocation]?.piece.color == "black" && whiteTurn == false {
                selectPiece(boardSquareLocation: boardSquareLocation)
            }
        }
        else if let _ = boardSquareToMove {
            if legalMoves.contains(boardSquareLocation) {//if a legal move square is clicked
                if castlingAvailable == true {//if castling is a legal move, and played
                    performCastle(boardSquareLocation: boardSquareLocation, boardSquareToMove: boardSquareToMove!)//castle
                }
                if enPassantAvailable == true {
                    performEnPassant(boardSquareLocation: boardSquareLocation, boardSquareToMove: boardSquareToMove!)
                }
                updateBoard(boardSquareLocation: boardSquareLocation)//moves pieces, clears legalmoves, records moves, checks for promotion, etc
                updateBoardView(buttons: buttonDict)//updates images
                checkforCheck(whiteKingLocation: whiteKingLocation, blackKingLocation: blackKingLocation)
            }
            //if it is white's turn and white clicks on another white piece
            else if boardDict[boardSquareLocation]?.piece.color == "white" && whiteTurn == true {
                selectPiece(boardSquareLocation: boardSquareLocation)
            }
            //if it is black's turn and black clicks on another black piece
            else if boardDict[boardSquareLocation]?.piece.color == "black" && whiteTurn == false {
                selectPiece(boardSquareLocation: boardSquareLocation)
            }
        }
    }
    
    func showLegalMoves(arr: Array<String>) {
        let legalMoves = arr
        //resets the display of legal moves for every click of a piece
        for l in letters {
            for n in numbers {
                //if theres no piece on a square, sets the image to nil
                if boardDict[l+n] == nil {
                    buttons[l+n]?.image = nil
                }
                //if there is a piece on a square, sets the image to the respective piece image
                if boardDict[l+n] != nil {
                    buttons[l+n]?.image = NSImage(named: (boardDict[l+n]?.piece.pieceType)! + "_" + (boardDict[l+n]?.piece.color)!)
                }
            }
        }
        //displays a dot for a legal move on a nil square, and adds corners capturable pieces
        for cord in legalMoves {
            if boardDict[cord] == nil {
                buttons[cord]?.image = NSImage(named: "legalmovedot")
            }
            else if boardDict[cord] != nil {
                buttons[cord]?.image = NSImage(named: (boardDict[cord]?.piece.pieceType)! + "_" + (boardDict[cord]?.piece.color)! + "_capture")
            }
        }
    }
    
    func selectPiece(boardSquareLocation: String) {
        legalMoves = []//clears legal moves
        legalMoves = getLegalMoves(boardSquareLocation: boardSquareLocation)//reassigns the legal moves of selected piece
        legalMoves = forcedToPreventCheck(whiteKingLocation: whiteKingLocation, blackKingLocation: blackKingLocation, pieceLocation: boardSquareLocation, legalMoves: legalMoves, whiteTurn: whiteTurn)
        boardSquareToMove = boardDict[boardSquareLocation]//sets the selected piece to the new piece
        originalCord = boardSquareLocation//saves the current coordinate of the piece
        showLegalMoves(arr: legalMoves)
    }
    
    func getLegalMoves(boardSquareLocation: String) -> Array<String> {//returns an array of legalMoves
        if let boardSquare = boardDict[boardSquareLocation] {//if there is a BoardSquare(a piece) at that coordinate, if not nothing happens
            let letterCord = boardSquareLocation.prefix(1)
            let numCord = boardSquareLocation.suffix(1)
            let letterIndex = letters.firstIndex(of: String(letterCord))!
            let numIndex = numbers.firstIndex(of: String(numCord))!
            var i = 1
            legalMoves = []
                
            if boardSquare.piece.pieceType == "pawn" {
                if boardSquare.piece.color == "white" {
                    if numIndex+1 <= 7 {
                        if boardDict[letterCord+numbers[numIndex+1]] == nil {//if there is no piece
                            legalMoves.append(letterCord+numbers[numIndex+1])//white pawn can move up 1 square
                    }
                        if boardSquare.piece.hasMoved == false {
                            if boardDict[letterCord+numbers[numIndex+2]] == nil && boardDict[letterCord+numbers[numIndex+1]] == nil{//if there is no piece on both squares in front
                                legalMoves.append(letterCord+numbers[numIndex+2])//if white pawn hasnt moved, it can move 2 squares
                            }
                        }
                    }

                    //white pawn can capture up right 1 square
                    if letterIndex+1 <= 7 && numIndex+1 <= 7 {
                        if boardDict[letters[letterIndex+1]+numbers[numIndex+1]] != nil {
                            if boardDict[letters[letterIndex+1]+numbers[numIndex+1]]?.piece.color != boardSquare.piece.color {
                                legalMoves.append(letters[letterIndex+1]+numbers[numIndex+1])
                            }
                        }
                    }
                    //white pawn can capture up left 1 square
                    if letterIndex-1 >= 0 && numIndex+1 <= 7 {
                        if boardDict[letters[letterIndex-1]+numbers[numIndex+1]] != nil {
                            if boardDict[letters[letterIndex-1]+numbers[numIndex+1]]?.piece.color != boardSquare.piece.color {
                                legalMoves.append(letters[letterIndex-1]+numbers[numIndex+1])
                            }
                        }
                    }
                    //en passant for white
                    if letterIndex-1 >= 0 && numCord == "5"{
                        if boardDict[letters[letterIndex-1]+numCord]?.piece.pieceType == "pawn" && boardDict[letters[letterIndex-1]+numCord]?.piece.color == "black" {
                            if movesArr[moveCount-2].blackOrg == letters[letterIndex-1] + "7" {
                                enPassantAvailable = true
                                legalMoves.append(letters[letterIndex-1] + "6")
                            }
                        }
                    }
                    if letterIndex+1 <= 7 && numCord == "5"{
                        if boardDict[letters[letterIndex+1]+numCord]?.piece.pieceType == "pawn" && boardDict[letters[letterIndex+1]+numCord]?.piece.color == "black" {
                            if movesArr[moveCount-2].blackOrg == letters[letterIndex+1] + "7" {
                                enPassantAvailable = true
                                legalMoves.append(letters[letterIndex+1] + "6")
                            }
                        }
                    }
                }
                if boardSquare.piece.color == "black" {
                    if numIndex-1 >= 0 {
                        if boardDict[letterCord+numbers[numIndex-1]] == nil {//if there is no piece
                            legalMoves.append(letterCord+numbers[numIndex-1])//black pawn can move down 1 square
                    }
                        if boardSquare.piece.hasMoved == false {
                            if boardDict[letterCord+numbers[numIndex-2]] == nil && boardDict[letterCord+numbers[numIndex-1]] == nil{//if there is no piece
                                legalMoves.append(letterCord+numbers[numIndex-2])//if black pawn hasnt moved, it can move 2 squares
                            }
                        }
                    }
                    //en passant for black
                    if letterIndex-1 >= 0 && numCord == "4"{
                        if boardDict[letters[letterIndex-1]+numCord]?.piece.pieceType == "pawn" && boardDict[letters[letterIndex-1]+numCord]?.piece.color == "white" {
                            if movesArr[moveCount-1].whiteOrg == letters[letterIndex-1] + "2" {
                                enPassantAvailable = true
                                legalMoves.append(letters[letterIndex-1] + "3")
                            }
                        }
                    }
                    if letterIndex+1 <= 7 && numCord == "4"{
                        if boardDict[letters[letterIndex+1]+numCord]?.piece.pieceType == "pawn" && boardDict[letters[letterIndex+1]+numCord]?.piece.color == "white" {
                            if movesArr[moveCount-1].whiteOrg == letters[letterIndex+1] + "2" {
                                enPassantAvailable = true
                                legalMoves.append(letters[letterIndex+1] + "3")
                            }
                        }
                    }
                    //black pawn can capture down right 1 square
                    if letterIndex+1 <= 7 && numIndex-1 >= 0{
                        if boardDict[letters[letterIndex+1]+numbers[numIndex-1]] != nil {
                            if boardDict[letters[letterIndex+1]+numbers[numIndex-1]]?.piece.color != boardSquare.piece.color {
                                legalMoves.append(letters[letterIndex+1]+numbers[numIndex-1])
                            }
                        }
                    }
                    //black pawn can capture down left 1 square
                    if letterIndex-1 >= 0 && numIndex-1 >= 0 {
                        if boardDict[letters[letterIndex-1]+numbers[numIndex-1]] != nil {
                            if boardDict[letters[letterIndex-1]+numbers[numIndex-1]]?.piece.color != boardSquare.piece.color {
                                legalMoves.append(letters[letterIndex-1]+numbers[numIndex-1])
                            }
                        }
                    }
                }
            }
            
            if boardSquare.piece.pieceType == "rook" {
                //left
                i = 1
                while letterIndex-i >= 0 {
                    if boardDict[letters[letterIndex-i]+numCord] != nil {//if there is a piece on a legal move square
                        if boardDict[letters[letterIndex-i]+numCord]?.piece.color != boardSquare.piece.color {// and the piece is opposite color
                            legalMoves.append(letters[letterIndex-i]+numCord)//it is a legal move
                        }
                        break
                    }
                    else {
                        legalMoves.append(letters[letterIndex-i]+numCord)//if there is no piece, append to legalmoves
                    }
                    i += 1
                }
                //right
                i = 1
                while letterIndex+i <= 7 {
                    if boardDict[letters[letterIndex+i]+numCord] != nil {
                        if boardDict[letters[letterIndex+i]+numCord]?.piece.color != boardSquare.piece.color {
                            legalMoves.append(letters[letterIndex+i]+numCord)
                        }
                        break
                    }
                    else {
                        legalMoves.append(letters[letterIndex+i]+numCord)
                    }
                    i += 1
                }
                //up
                i = 1
                while numIndex+i <= 7 {
                    if boardDict[letterCord+numbers[numIndex+i]] != nil {
                        if boardDict[letterCord+numbers[numIndex+i]]?.piece.color != boardSquare.piece.color {
                            legalMoves.append(letterCord+numbers[numIndex+i])
                        }
                        break
                    }
                    else {
                        legalMoves.append(letterCord+numbers[numIndex+i])
                    }
                    i += 1
                }
                //down
                i = 1
                while numIndex-i >= 0 {
                    if boardDict[letterCord+numbers[numIndex-i]] != nil {
                        if boardDict[letterCord+numbers[numIndex-i]]?.piece.color != boardSquare.piece.color {
                            legalMoves.append(letterCord+numbers[numIndex-i])
                        }
                        break
                    }
                    else {
                        legalMoves.append(letterCord+numbers[numIndex-i])
                    }
                    i += 1
                }
            }
            if boardSquare.piece.pieceType == "knight" {
                //possible coordinate moves: +1,+2; -1,+2; -2,+1; -2,-1; -1,-2; +1,-2; +2,-1; +2;+1
                //unfortunately, I'm not sure of a way to for loop the knight moves, so it has to be hardcoded.
                if letterIndex+1 <= 7 && numIndex+2 <= 7 {
                    if boardDict[letters[letterIndex+1]+numbers[numIndex+2]]?.piece.color != boardSquare.piece.color {
                        legalMoves.append(letters[letterIndex+1]+numbers[numIndex+2])
                    }
                }
                if letterIndex-1 >= 0 && numIndex+2 <= 7 {
                    if boardDict[letters[letterIndex-1]+numbers[numIndex+2]]?.piece.color != boardSquare.piece.color {
                        legalMoves.append(letters[letterIndex-1]+numbers[numIndex+2])
                    }
                }
                if letterIndex-2 >= 0 && numIndex+1 <= 7 {
                    if boardDict[letters[letterIndex-2]+numbers[numIndex+1]]?.piece.color != boardSquare.piece.color {
                        legalMoves.append(letters[letterIndex-2]+numbers[numIndex+1])
                    }
                }
                if letterIndex-2 >= 0 && numIndex-1 >= 0 {
                    if boardDict[letters[letterIndex-2]+numbers[numIndex-1]]?.piece.color != boardSquare.piece.color {
                        legalMoves.append(letters[letterIndex-2]+numbers[numIndex-1])
                    }
                }
                if letterIndex-1 >= 0 && numIndex-2 >= 0 {
                    if boardDict[letters[letterIndex-1]+numbers[numIndex-2]]?.piece.color != boardSquare.piece.color {
                        legalMoves.append(letters[letterIndex-1]+numbers[numIndex-2])
                    }
                }
                if letterIndex+1 <= 7 && numIndex-2 >= 0 {
                    if boardDict[letters[letterIndex+1]+numbers[numIndex-2]]?.piece.color != boardSquare.piece.color {
                        legalMoves.append(letters[letterIndex+1]+numbers[numIndex-2])
                    }
                }
                if letterIndex+2 <= 7 && numIndex-1 >= 0 {
                    if boardDict[letters[letterIndex+2]+numbers[numIndex-1]]?.piece.color != boardSquare.piece.color {
                        legalMoves.append(letters[letterIndex+2]+numbers[numIndex-1])
                    }
                }
                if letterIndex+2 <= 7 && numIndex+1 <= 7 {
                    if boardDict[letters[letterIndex+2]+numbers[numIndex+1]]?.piece.color != boardSquare.piece.color {
                        legalMoves.append(letters[letterIndex+2]+numbers[numIndex+1])
                    }
                }
            }
            if boardSquare.piece.pieceType == "bishop" {
                //up right diagonal
                i = 1
                while letterIndex+i <= 7 && numIndex+i <= 7{
                    if boardDict[letters[letterIndex+i]+numbers[numIndex+i]] != nil {//if there is a piece on a legal move square
                        if boardDict[letters[letterIndex+i]+numbers[numIndex+i]]?.piece.color != boardSquare.piece.color {//and it is opposite color
                            legalMoves.append(letters[letterIndex+i]+numbers[numIndex+i])//it is a legal move
                        }
                        break
                    }
                    else {
                        legalMoves.append(letters[letterIndex+i]+numbers[numIndex+i])//if there is no piece, it is a legal move
                    }
                    i += 1
                }
                //down left diagonal
                i = 1
                while letterIndex-i >= 0 && numIndex-i >= 0{
                    if boardDict[letters[letterIndex-i]+numbers[numIndex-i]] != nil {
                        if boardDict[letters[letterIndex-i]+numbers[numIndex-i]]?.piece.color != boardSquare.piece.color {
                            legalMoves.append(letters[letterIndex-i]+numbers[numIndex-i])
                        }
                        break
                    }
                    else {
                        legalMoves.append(letters[letterIndex-i]+numbers[numIndex-i])
                    }
                    i += 1
                }
                //down right diagonal
                i = 1
                while letterIndex+i <= 7 && numIndex-i >= 0{
                    if boardDict[letters[letterIndex+i]+numbers[numIndex-i]] != nil {
                        if boardDict[letters[letterIndex+i]+numbers[numIndex-i]]?.piece.color != boardSquare.piece.color {
                            legalMoves.append(letters[letterIndex+i]+numbers[numIndex-i])
                        }
                        break
                    }
                    else {
                        legalMoves.append(letters[letterIndex+i]+numbers[numIndex-i])
                    }
                    i += 1
                }
                //up left diagonal
                i = 1
                while letterIndex-i >= 0 && numIndex+i <= 7{
                    if boardDict[letters[letterIndex-i]+numbers[numIndex+i]] != nil {
                        if boardDict[letters[letterIndex-i]+numbers[numIndex+i]]?.piece.color != boardSquare.piece.color {
                            legalMoves.append(letters[letterIndex-i]+numbers[numIndex+i])
                        }
                        break
                    }
                    else {
                        legalMoves.append(letters[letterIndex-i]+numbers[numIndex+i])
                    }
                    i += 1
                }
            }

            if boardSquare.piece.pieceType == "queen"{
                //left
                i = 1
                while letterIndex-i >= 0 {
                    if boardDict[letters[letterIndex-i]+numCord] != nil {//if there is a piece on a legal move square
                        if boardDict[letters[letterIndex-i]+numCord]?.piece.color != boardSquare.piece.color {// and the piece is opposite color
                            legalMoves.append(letters[letterIndex-i]+numCord)//it is a legal move
                        }
                        break
                    }
                    else {
                        legalMoves.append(letters[letterIndex-i]+numCord)//if there is no piece, append to legalmoves
                    }
                    i += 1
                }
                //right
                i = 1
                while letterIndex+i <= 7 {
                    if boardDict[letters[letterIndex+i]+numCord] != nil {
                        if boardDict[letters[letterIndex+i]+numCord]?.piece.color != boardSquare.piece.color {
                            legalMoves.append(letters[letterIndex+i]+numCord)
                        }
                        break
                    }
                    else {
                        legalMoves.append(letters[letterIndex+i]+numCord)
                    }
                    i += 1
                }
                //up
                i = 1
                while numIndex+i <= 7 {
                    if boardDict[letterCord+numbers[numIndex+i]] != nil {
                        if boardDict[letterCord+numbers[numIndex+i]]?.piece.color != boardSquare.piece.color {
                            legalMoves.append(letterCord+numbers[numIndex+i])
                        }
                        break
                    }
                    else {
                        legalMoves.append(letterCord+numbers[numIndex+i])
                    }
                    i += 1
                }
                //down
                i = 1
                while numIndex-i >= 0 {
                    if boardDict[letterCord+numbers[numIndex-i]] != nil {
                        if boardDict[letterCord+numbers[numIndex-i]]?.piece.color != boardSquare.piece.color {
                            legalMoves.append(letterCord+numbers[numIndex-i])
                        }
                        break
                    }
                    else {
                        legalMoves.append(letterCord+numbers[numIndex-i])
                    }
                    i += 1
                }
                //up right diagonal
                i = 1
                while letterIndex+i <= 7 && numIndex+i <= 7{
                    if boardDict[letters[letterIndex+i]+numbers[numIndex+i]] != nil {//if there is a piece on a legal move square
                        if boardDict[letters[letterIndex+i]+numbers[numIndex+i]]?.piece.color != boardSquare.piece.color {//and it is opposite color
                            legalMoves.append(letters[letterIndex+i]+numbers[numIndex+i])//it is a legal move
                        }
                        break
                    }
                    else {
                        legalMoves.append(letters[letterIndex+i]+numbers[numIndex+i])//if there is no piece, it is a legal move
                    }
                    i += 1
                }
                //down left diagonal
                i = 1
                while letterIndex-i >= 0 && numIndex-i >= 0{
                    if boardDict[letters[letterIndex-i]+numbers[numIndex-i]] != nil {
                        if boardDict[letters[letterIndex-i]+numbers[numIndex-i]]?.piece.color != boardSquare.piece.color {
                            legalMoves.append(letters[letterIndex-i]+numbers[numIndex-i])
                        }
                        break
                    }
                    else {
                        legalMoves.append(letters[letterIndex-i]+numbers[numIndex-i])
                    }
                    i += 1
                }
                //down right diagonal
                i = 1
                while letterIndex+i <= 7 && numIndex-i >= 0{
                    if boardDict[letters[letterIndex+i]+numbers[numIndex-i]] != nil {
                        if boardDict[letters[letterIndex+i]+numbers[numIndex-i]]?.piece.color != boardSquare.piece.color {
                            legalMoves.append(letters[letterIndex+i]+numbers[numIndex-i])
                        }
                        break
                    }
                    else {
                        legalMoves.append(letters[letterIndex+i]+numbers[numIndex-i])
                    }
                    i += 1
                }
                //up left diagonal
                i = 1
                while letterIndex-i >= 0 && numIndex+i <= 7{
                    if boardDict[letters[letterIndex-i]+numbers[numIndex+i]] != nil {
                        if boardDict[letters[letterIndex-i]+numbers[numIndex+i]]?.piece.color != boardSquare.piece.color {
                            legalMoves.append(letters[letterIndex-i]+numbers[numIndex+i])
                        }
                        break
                    }
                    else {
                        legalMoves.append(letters[letterIndex-i]+numbers[numIndex+i])
                    }
                    i += 1
                }
            }
            if boardSquare.piece.pieceType == "king" {
                //can move one square in any direction
                for i in -1...1 {
                    for j in -1...1 {
                        //if cord is on board; if there is a piece there, if piece is opposite color, it is a legal move
                        if letterIndex+i >= 0 && numIndex+j >= 0 && letterIndex+i <= 7 && numIndex+j <= 7 {
                            if boardDict[letters[letterIndex+i] + numbers[numIndex + j]] != nil {
                                if boardDict[letters[letterIndex+i] + numbers[numIndex + j]]?.piece.color != boardSquare.piece.color {
                                    legalMoves.append(letters[letterIndex+i] + numbers[numIndex + j])
                                }
                            }
                            else {//if there is no piece on the square
                                legalMoves.append(letters[letterIndex+i] + numbers[numIndex + j])//it is a legal move
                            }
                        }
                    }
                }
                //castling
                if boardSquare.piece.hasMoved == false {
                    if boardSquare.piece.color == "white" {//white castling
                        if boardDict["H1"]?.piece.hasMoved == false {//kingside
                            if boardDict["F1"] == nil && boardDict["G1"] == nil {
                                if (blackTotalLegalMoves.contains("F1") == false) && (blackTotalLegalMoves.contains("G1") == false) {
                                    legalMoves.append("G1")
                                    castlingAvailable = true
                                }
                            }
                        }
                        if boardDict["A1"]?.piece.hasMoved == false {//queenside
                            if boardDict["D1"] == nil && boardDict["C1"] == nil && boardDict["B1"] == nil {
                                if blackTotalLegalMoves.contains("D1") == false && blackTotalLegalMoves.contains("C1") == false && blackTotalLegalMoves.contains("B1") == false {
                                    legalMoves.append("C1")
                                    castlingAvailable = true
                                }
                            }
                        }
                    }
                    if boardSquare.piece.color == "black" {//black castling
                        if boardDict["H8"]?.piece.hasMoved == false {//kingside
                            if boardDict["F8"] == nil && boardDict["G8"] == nil {
                                if whiteTotalLegalMoves.contains("F8") == false && whiteTotalLegalMoves.contains("G8") == false {
                                    legalMoves.append("G8")
                                    castlingAvailable = true
                                }
                            }
                        }
                        if boardDict["A8"]?.piece.hasMoved == false {//queenside
                            if boardDict["D8"] == nil && boardDict["C8"] == nil && boardDict["B8"] == nil {
                                if whiteTotalLegalMoves.contains("D8") == false && whiteTotalLegalMoves.contains("C8") == false && whiteTotalLegalMoves.contains("B8") == false {
                                    legalMoves.append("C8")
                                    castlingAvailable = true
                                }
                            }
                        }
                    }
                }
            }
        }
        return legalMoves
    }
    
    func setBoardDict(buttons: [String:NSButton]) {
        self.buttons = buttons
        //initializing all boardDict values as nil
        for l in letters {
            for n in numbers {
                boardDict[l+n] = nil
            }
        }
        //board setup
        //white
        for l in letters {
            boardDict[l+"2"] = BoardSquare(piece: Piece(pieceType: "pawn", color: "white", value: 1, hasMoved: false, pieceLegalMoves: Array<String>()), button: buttons[l+"2"]!)
        }
        boardDict["A1"] = BoardSquare(piece: Piece(pieceType: "rook", color: "white", value: 5, hasMoved: false, pieceLegalMoves: Array<String>()), button: buttons["A1"]!)
        boardDict["H1"] = BoardSquare(piece: Piece(pieceType: "rook", color: "white", value: 5, hasMoved: false, pieceLegalMoves: Array<String>()), button: buttons["H1"]!)
        boardDict["B1"] = BoardSquare(piece: Piece(pieceType: "knight", color: "white", value: 3, hasMoved: false, pieceLegalMoves: Array<String>()), button: buttons["B1"]!)
        boardDict["G1"] = BoardSquare(piece: Piece(pieceType: "knight", color: "white", value: 3, hasMoved: false, pieceLegalMoves: Array<String>()), button: buttons["G1"]!)
        boardDict["C1"] = BoardSquare(piece: Piece(pieceType: "bishop", color: "white", value: 3, hasMoved: false, pieceLegalMoves: Array<String>()), button: buttons["C1"]!)
        boardDict["F1"] = BoardSquare(piece: Piece(pieceType: "bishop", color: "white", value: 3, hasMoved: false, pieceLegalMoves: Array<String>()), button: buttons["F1"]!)
        boardDict["E1"] = BoardSquare(piece: Piece(pieceType: "king", color: "white", value: 0, hasMoved: false, pieceLegalMoves: Array<String>()), button: buttons["E1"]!)
        boardDict["D1"] = BoardSquare(piece: Piece(pieceType: "queen", color: "white", value: 9, hasMoved: false, pieceLegalMoves: Array<String>()), button: buttons["D1"]!)

        //black
        for l in letters {
            boardDict[l+"7"] = BoardSquare(piece: Piece(pieceType: "pawn", color: "black", value: 1, hasMoved: false, pieceLegalMoves: Array<String>()), button:buttons[l+"7"]!)
        }
        boardDict["A8"] = BoardSquare(piece: Piece(pieceType: "rook", color: "black", value: 5, hasMoved: false, pieceLegalMoves: Array<String>()), button:buttons["A8"]!)
        boardDict["H8"] = BoardSquare(piece: Piece(pieceType: "rook", color: "black", value: 5, hasMoved: false, pieceLegalMoves: Array<String>()), button:buttons["H8"]!)
        boardDict["B8"] = BoardSquare(piece: Piece(pieceType: "knight", color: "black", value: 3, hasMoved: false, pieceLegalMoves: Array<String>()), button:buttons["B8"]!)
        boardDict["G8"] = BoardSquare(piece: Piece(pieceType: "knight", color: "black", value: 3, hasMoved: false, pieceLegalMoves: Array<String>()), button:buttons["G8"]!)
        boardDict["C8"] = BoardSquare(piece: Piece(pieceType: "bishop", color: "black", value: 3, hasMoved: false, pieceLegalMoves: Array<String>()), button:buttons["C8"]!)
        boardDict["F8"] = BoardSquare(piece: Piece(pieceType: "bishop", color: "black", value: 3, hasMoved: false, pieceLegalMoves: Array<String>()), button:buttons["F8"]!)
        boardDict["E8"] = BoardSquare(piece: Piece(pieceType: "king", color: "black", value: 0, hasMoved: false, pieceLegalMoves: Array<String>()), button:buttons["E8"]!)
        boardDict["D8"] = BoardSquare(piece: Piece(pieceType: "queen", color: "black", value: 9, hasMoved: false, pieceLegalMoves: Array<String>()), button:buttons["D8"]!)
    }
    
    func performCastle(boardSquareLocation: String, boardSquareToMove: BoardSquare) {
        if boardSquareLocation == "G1" && boardSquareToMove.piece.pieceType == "king" {//white kingside
            boardDict["F1"] = boardDict["H1"]
            boardSquareToMove.piece.hasMoved = true
            boardDict[originalCord] = nil
            boardDict["H1"]?.piece.hasMoved = true
            boardDict["H1"] = nil
            castlingAvailable = false
        }
        if boardSquareLocation == "C1" && boardSquareToMove.piece.pieceType == "king" {//white queenside
            boardDict["D1"] = boardDict["A1"]
            boardSquareToMove.piece.hasMoved = true
            boardDict[originalCord] = nil
            boardDict["A1"]?.piece.hasMoved = true
            boardDict["A1"] = nil
            castlingAvailable = false
        }
        if boardSquareLocation == "G8" && boardSquareToMove.piece.pieceType == "king" {//black kingside
            boardDict["F8"] = boardDict["H8"]
            boardSquareToMove.piece.hasMoved = true
            boardDict[originalCord] = nil
            boardDict["H8"]?.piece.hasMoved = true
            boardDict["H8"] = nil
            castlingAvailable = false
        }
        if boardSquareLocation == "C8" && boardSquareToMove.piece.pieceType == "king" {//black queenside
            boardDict["D8"] = boardDict["A8"]
            boardSquareToMove.piece.hasMoved = true
            boardDict[originalCord] = nil
            boardDict["A8"]?.piece.hasMoved = true
            boardDict["A8"] = nil
            castlingAvailable = false
        }
    }
    
    func performEnPassant(boardSquareLocation: String, boardSquareToMove: BoardSquare) {
        let letterCord = boardSquareLocation.prefix(1)
        let numCord = boardSquareLocation.suffix(1)
        let numIndex = numbers.firstIndex(of: String(numCord))!
        //white
        if boardSquareToMove.piece.color == "white" {
            boardDict[boardSquareLocation] = boardSquareToMove//move pawn to new location
            boardDict[letterCord+numbers[numIndex-1]] = nil//remove pawn that got en passant'd
        }
        //black
        else if boardSquareToMove.piece.color == "black" {
            boardDict[boardSquareLocation] = boardSquareToMove//move pawn to new location
            boardDict[letterCord+numbers[numIndex+1]] = nil//remove pawn that got en passant'd
        }
    }
    
    func promotionAvailable() -> Bool {
        for l in letters {
            if boardDict[l+"8"]?.piece.pieceType == "pawn" {
                return true
            }
            if boardDict[l+"1"]?.piece.pieceType == "pawn" {
                return true
            }
        }
        return false
    }
    
    func promoteToQueen(boardSquareLocation: String){//if is on back rank, creates a new piece object of queen
        if boardDict[boardSquareLocation]?.piece.color == "white" {
            boardDict[boardSquareLocation] = BoardSquare(piece: Piece(pieceType: "queen", color: "white", value: 9, hasMoved: true, pieceLegalMoves: Array<String>()), button: buttons[boardSquareLocation]!)
        }
        else {
            boardDict[boardSquareLocation] = BoardSquare(piece: Piece(pieceType: "queen", color: "black", value: 9, hasMoved: true, pieceLegalMoves: Array<String>()), button: buttons[boardSquareLocation]!)
        }
    }
    
    func setGlobalVariables(localWhiteScore: NSTextField, localBlackScore: NSTextField, localMoveCount: NSTextField, localCheckMateText: NSTextField, localwhiteScoreImageViews: Array<NSImageView>, localblackScoreImageViews: Array<NSImageView>, localtableView: NSTableView) {
        globalWhiteScore = localWhiteScore
        globalBlackScore = localBlackScore
        globalMoveCountDisplay = localMoveCount
        globalCheckMateText = localCheckMateText
        globalwhiteScoreImageViews = localwhiteScoreImageViews
        globalblackScoreImageViews = localblackScoreImageViews
        moveCount = 1
        tableView = localtableView
    }
    
    func updateMaterialValue(boardSquareLocation: String) {
        //resets material to empty arrays
        blackMaterial = []
        whiteMaterial = []
        //adds all material to respective arrays
        for l in letters {
            for n in numbers {
                if boardDict[l+n] != nil {
                    if boardDict[l+n]?.piece.color == "white" {whiteMaterial.append(boardDict[l+n]!.piece)}
                    if boardDict[l+n]?.piece.color == "black" {blackMaterial.append(boardDict[l+n]!.piece)}
                }
            }
        }
        for i in stride(from: whiteMaterial.count-1, to: -1, by: -1) {
            for j in stride(from: blackMaterial.count-1, to: -1, by: -1) {
                //remove duplicates, so only the inbalance in material shows
                if whiteMaterial[i].pieceType == blackMaterial[j].pieceType {
                    whiteMaterial.remove(at: i)
                    blackMaterial.remove(at: j)
                    break
                }
            }
        }
    }
    
    func showMaterialValue(globalWhiteScore: NSTextField, globalBlackScore: NSTextField) {
        var whiteMaterialValue = 0
        var blackMaterialValue = 0
        for l in letters {
            for n in numbers {
                if boardDict[l+n]?.piece.color == "white" {
                    whiteMaterialValue += (boardDict[l+n]?.piece.value)!
                }
                else if boardDict[l+n]?.piece.color == "black" {
                    blackMaterialValue += (boardDict[l+n]?.piece.value)!
                }
            }
        }
        let whiteNumScore = whiteMaterialValue-blackMaterialValue
        let blackNumScore = blackMaterialValue-whiteMaterialValue
        
        if whiteNumScore > 0 {
            globalWhiteScore.stringValue = "+" + String(whiteNumScore)
            globalWhiteScore.setFrameOrigin(NSPoint(x:46 + (whiteMaterial.count * 20), y: 46))
        }
        else {
            globalWhiteScore.stringValue = " "
        }
        if blackNumScore > 0 {
            globalBlackScore.stringValue = "+" + String(blackNumScore)
            globalBlackScore.setFrameOrigin(NSPoint(x:46 + (blackMaterial.count * 20), y: 22))
        }
        else {
            globalBlackScore.stringValue = " "
        }
        
        //ordering the arrays
        if blackMaterial.count > 1 {
            for index in stride(from: blackMaterial.count-1, to: 0, by: -1) {
                if blackMaterial[index].value > blackMaterial[index-1].value {
                    blackMaterial.insert(blackMaterial[index], at: index-1)
                    blackMaterial.remove(at: index+1)
                }
            }
        }
        if whiteMaterial.count > 1 {
            for index in stride(from: whiteMaterial.count-1, to: 0, by: -1) {
                if whiteMaterial[index].value > whiteMaterial[index-1].value {
                    whiteMaterial.insert(whiteMaterial[index], at: index-1)
                    whiteMaterial.remove(at: index+1)
                }
            }
        }
        //clearing the piece images
        for imageView in globalwhiteScoreImageViews {
            imageView.image = nil
        }
        for imageView in globalblackScoreImageViews {
            imageView.image = nil
        }
        //displaying the piece images
        if blackMaterial.count > 0 {
            for index in 0...blackMaterial.count-1 {
                globalblackScoreImageViews[index].image = NSImage(named: blackMaterial[index].pieceType + "_white")
            }
        }
        if whiteMaterial.count > 0 {
            for index in 0...whiteMaterial.count-1 {
                globalwhiteScoreImageViews[index].image = NSImage(named: whiteMaterial[index].pieceType + "_black")
            }
        }
    }
    
    func showMoveCount() {
        globalMoveCountDisplay.stringValue = "Move: " + String(moveCount)
    }

    //returns an array of all legal moves, disregarding discovered checks
    func legalMovesOfColor(color: String) -> Array<String>{
        var totalLegalMoves = Array<String>()
        for l in letters {
            for n in numbers {
                if boardDict[l+n]?.piece.color == color {
                    totalLegalMoves.append(contentsOf: getLegalMoves(boardSquareLocation: l+n))
                }
            }
        }
        return totalLegalMoves
    }
    
    //returns an array of all legal moves, checking for discovered checks into account
    func updatedLegalMovesOfColor(color: String) -> Array<String> {
        var updatedTotalLegalMoves = Array<String>()
        for l in letters {
            for n in numbers {
                if boardDict[l+n]?.piece.color == color {
                    if color == "white" {//to see which kingLocation to use
                        let tempLegalMoves = getLegalMoves(boardSquareLocation: l+n)
                        for index in stride(from: tempLegalMoves.count-1, to: -1, by: -1) {
                            if checkLegalMove(kingLocation: whiteKingLocation, pieceLocation: l+n, newLocation: tempLegalMoves[index], whiteTurn: true) == true {//simulates if the legalmove is actually legal
                                updatedTotalLegalMoves.append(tempLegalMoves[index])
                            }
                        }
                    }
                    else if color == "black" {
                        let tempLegalMoves = getLegalMoves(boardSquareLocation: l+n)
                        for index in stride(from: tempLegalMoves.count-1, to: -1, by: -1) {
                            if checkLegalMove(kingLocation: blackKingLocation, pieceLocation: l+n, newLocation: tempLegalMoves[index], whiteTurn: false) == true {
                                updatedTotalLegalMoves.append(tempLegalMoves[index])
                            }
                        }
                    }
                }
            }
        }
        return updatedTotalLegalMoves
    }
    
    //simulates the move of a piece, to see if it would put or keep the king in check
    func checkLegalMove(kingLocation: String, pieceLocation: String, newLocation: String, whiteTurn: Bool) -> Bool{
        let orgPieceLocation = boardDict[pieceLocation]
        let orgNewLocation = boardDict[newLocation]
        var kingLocation = kingLocation
        
        if pieceLocation == kingLocation {
            kingLocation = newLocation
        }
        boardDict[newLocation] = boardDict[pieceLocation]
        boardDict[pieceLocation] = nil
        if whiteTurn == true {
            movesArr.append(Move(whiteOrg: pieceLocation, whiteNew: newLocation))
        }
        else {
            if moveCount == 1 {
                movesArr[moveCount-1].setBlackMove(blackOrg: pieceLocation, blackNew: newLocation)
            }
            if moveCount > 1 {
                movesArr[moveCount-2].setBlackMove(blackOrg: pieceLocation, blackNew: newLocation)
            }
        }
        
        if whiteTurn == true {//white
            blackTotalLegalMoves = legalMovesOfColor(color: "black")
            if blackTotalLegalMoves.contains(kingLocation) == true {//if white is in check
                boardDict[pieceLocation] = orgPieceLocation//reset the pieces
                boardDict[newLocation] = orgNewLocation
                blackTotalLegalMoves = legalMovesOfColor(color: "black")
                movesArr.removeLast()
                return false//it is not a legal move
            }
        }
        if whiteTurn == false {//black
            whiteTotalLegalMoves = legalMovesOfColor(color: "white")
            if whiteTotalLegalMoves.contains(kingLocation) == true {//if black is in check
                boardDict[pieceLocation] = orgPieceLocation
                boardDict[newLocation] = orgNewLocation
                whiteTotalLegalMoves = legalMovesOfColor(color: "white")
                movesArr[moveCount-1].blackOrg = " "
                movesArr[moveCount-1].blackNew = " "
                return false
            }
        }
        boardDict[pieceLocation] = orgPieceLocation
        boardDict[newLocation] = orgNewLocation
        blackTotalLegalMoves = legalMovesOfColor(color: "black")
        whiteTotalLegalMoves = legalMovesOfColor(color: "white")
        if whiteTurn == true {
            movesArr.removeLast()
        }
        else {
            if moveCount == 1 {
                movesArr[moveCount-1].blackOrg = " "
                movesArr[moveCount-1].blackNew = " "
            }
            if moveCount > 1 {
                movesArr[moveCount-2].blackOrg = " "
                movesArr[moveCount-2].blackNew = " "
            }
        }
        return true//if the move does not put the king in check, it is legal
    }
    
    func forcedToPreventCheck(whiteKingLocation: String, blackKingLocation: String, pieceLocation: String, legalMoves: Array<String>, whiteTurn: Bool) -> Array<String> {
        var tempLegalMoves = legalMoves
        
        for index in stride(from: legalMoves.count-1, to: -1, by: -1) {
            if whiteTurn == true {
                if checkLegalMove(kingLocation: whiteKingLocation, pieceLocation: pieceLocation, newLocation: legalMoves[index], whiteTurn: whiteTurn) == false {
                    tempLegalMoves.remove(at: index)
                }
            }
            else if whiteTurn == false {
                if checkLegalMove(kingLocation: blackKingLocation, pieceLocation: pieceLocation, newLocation: legalMoves[index], whiteTurn: whiteTurn) == false {
                    tempLegalMoves.remove(at: index)
                }
            }
        }
        return tempLegalMoves
    }
    
    //if either side is in check, calls inCheck()
    func checkforCheck(whiteKingLocation: String, blackKingLocation: String) {
        if whiteTurn == true {
            if legalMovesOfColor(color: "black").contains(whiteKingLocation) {
                inCheck(kingLocation: whiteKingLocation, color: "white")
            }
        }
        if whiteTurn == false {
            if legalMovesOfColor(color: "white").contains(blackKingLocation) {
                inCheck(kingLocation: blackKingLocation, color: "black")
            }
        }
    }
    
    func inCheck(kingLocation: String, color: String) {
        buttons[kingLocation]!.image = NSImage(named: "king_" + color + "_check")
        checkForCheckMate()
    }
    
    func checkForCheckMate() {
        if updatedLegalMovesOfColor(color: "white").isEmpty {
            globalCheckMateText.stringValue = "Black wins by checkmate"
        }
        if updatedLegalMovesOfColor(color: "black").isEmpty {
            globalCheckMateText.stringValue = "White wins by checkmate" 
        }
    }
    func recordMove(orginalCord: String, boardSquareLocation: String) {
        if whiteTurn == true {
            movesArr.append(Move(whiteOrg: originalCord, whiteNew: boardSquareLocation))
        }
        else {
            movesArr[moveCount-1].setBlackMove(blackOrg: originalCord, blackNew: boardSquareLocation)
        }
        tableView.reloadData()
    }
    func updateKingLocation(boardSquareLocation: String) {
        //if the kings move, update the king location variable
        if boardSquareToMove?.piece.pieceType == "king" && boardSquareToMove?.piece.color == "white" {
            whiteKingLocation = boardSquareLocation
        }
        if boardSquareToMove?.piece.pieceType == "king" && boardSquareToMove?.piece.color == "black" {
            blackKingLocation = boardSquareLocation
        }
    }
}
