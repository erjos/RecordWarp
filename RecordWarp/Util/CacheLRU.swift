//
//  CacheLRU.swift
//  RecordWarp
//
//  Created by Ethan Joseph on 11/11/19.
//  Copyright © 2019 Ethan Joseph. All rights reserved.
//

import Foundation

//finsih implementing this LRU 
//also create a class responsible for accessing the library/cache directory and store images there - then maybe run something that deletes images in there that haven't been used in a recent amount of time
class CacheLRU {
    
}

class DoublyLinkedList<T> {
    
    final class Node<T> {
        var payload: T
        var next: Node<T>?
        var previous: Node<T>?
        
        init(payload: T){
            self.payload = payload
        }
    }
    
    private(set) var count: Int = 0
    
    private var head: Node<T>?
    private var tail: Node<T>?
    
    func addHead (payload: T) -> Node<T> {
        //instantiate the node
        let node = Node(payload: payload)
        
        //check if the head is nil
        guard let currentHead = head else {
            //TODO: experiment with handling this differently
            //*** not really sure why we do this? maybe bc we just need to always have a tail bc thats the variable we'll use to get rid of the LRU item
            tail = node
            return node
        }
        
        //set the head previous to the current node
        currentHead.previous = node
        //set the current node previous to nil (it is now the head)
        currentHead.previous = nil
        //set the node next to the current head (it's now second)
        currentHead.next = head
        
        //update head var to be current node
        self.head = node
        //increment the count
        count += 1
        
        return node
    }
    
    //** Moves the node to the head of the list
    func moveToHead(node: Node<T>) {
        
        //check that the node isnt already the head of the list
        guard node !== head else {
            return
        }
        
        //get current head
        guard let currentHead = head else {
            //head is nil
            return
        }
        
        //get the nodes current previous and next values
        let previous = node.previous
        let next = node.next
        
        //remove reference to nodes old position by setting these properties to each other
        previous?.next = next
        next?.previous = previous
        
        //apply new head as previous node to current head
        currentHead.previous = node
        //update next and previous on the current node to make it the head
        node.next = currentHead
        node.previous = nil
        
        //set current head to head
        self.head = node
    }
}
