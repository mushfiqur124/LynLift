import Foundation

struct SupabaseConfig {
    // IMPORTANT: Never commit real credentials to source control!
    // Use environment variables or a secure configuration method
    
    static let url: String = {
        if let path = Bundle.main.path(forResource: "SupabaseConfig", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let url = plist["SUPABASE_URL"] as? String {
            return url
        }
        
        // Fallback - you should replace this with your actual URL
        return "https://sydvqphltgzmfhidiwsd.supabase.co"
    }()
    
    static let anonKey: String = {
        if let path = Bundle.main.path(forResource: "SupabaseConfig", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let key = plist["SUPABASE_ANON_KEY"] as? String {
            return key
        }
        
        // Fallback - this will cause the app to fail if plist is not configured
        fatalError("SupabaseConfig.plist not found or missing SUPABASE_ANON_KEY. Please add your Supabase credentials to SupabaseConfig.plist")
    }()
}

// MARK: - Development Notes
/*
 SECURITY BEST PRACTICES:
 
 1. NEVER commit API keys to source control
 2. Use SupabaseConfig.plist for configuration (already in .gitignore)
 3. For production, use environment variables or secure storage
 4. Use different keys for development/production
 
 Setup Instructions:
 1. Add SupabaseConfig.plist to your Xcode project
 2. Add your new Supabase credentials to the plist
 3. The plist is automatically excluded from git commits
 */ 