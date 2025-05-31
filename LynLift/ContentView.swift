//
//  ContentView.swift
//  LynLift
//
//  Created by Mushfiqur Rahman on 2025-05-31.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @ObservedObject private var supabaseService = SupabaseService.shared
    
    var body: some View {
        Group {
            if supabaseService.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: supabaseService.isAuthenticated)
    }
}

#Preview {
    ContentView()
}
