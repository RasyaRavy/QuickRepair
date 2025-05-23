import 'package:http/http.dart' as http;
import 'dart:convert';

// A utility script to create a Supabase storage bucket and set permissions
// Run this script with: dart lib/utils/create_bucket.dart

void main() async {
  const supabaseUrl = 'https://galamhpjjcfyiusmriiq.supabase.co';
  const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdhbGFtaHBqamNmeWl1c21yaWlxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc0MDM5ODAsImV4cCI6MjA2Mjk3OTk4MH0.3JEODbI3w300D28pEtO1m-inDpllIu2MQNcQG-cE0Eg';
  
  // Create headers
  final headers = {
    'Content-Type': 'application/json',
    'apikey': supabaseKey,
    'Authorization': 'Bearer $supabaseKey',
  };
  
  // 1. Create the bucket
  try {
    print('Creating bucket...');
    final createBucketUrl = '$supabaseUrl/rest/v1/storage/buckets';
    final createBucketResponse = await http.post(
      Uri.parse(createBucketUrl),
      headers: headers,
      body: jsonEncode({
        'id': 'report_photos',
        'name': 'Report Photos',
        'public': true,
      }),
    );
    
    if (createBucketResponse.statusCode == 200 || createBucketResponse.statusCode == 201) {
      print('Bucket created successfully!');
    } else if (createBucketResponse.statusCode == 409) {
      print('Bucket already exists.');
    } else {
      print('Failed to create bucket: ${createBucketResponse.statusCode}');
      print(createBucketResponse.body);
      return;
    }
    
    // 2. Create bucket policies - allow public access to read images
    print('Setting bucket policies...');
    final policiesUrl = '$supabaseUrl/rest/v1/storage/buckets/report_photos/policies';
    
    // Allow authenticated users to upload
    final uploadPolicyResponse = await http.post(
      Uri.parse(policiesUrl),
      headers: headers,
      body: jsonEncode({
        'name': 'allow authenticated uploads',
        'definition': {
          'role_id': 'authenticated',
          'operations': ['INSERT', 'UPDATE'],
        },
      }),
    );
    
    if (uploadPolicyResponse.statusCode == 200 || uploadPolicyResponse.statusCode == 201) {
      print('Upload policy created successfully!');
    } else if (uploadPolicyResponse.statusCode == 409) {
      print('Upload policy already exists.');
    } else {
      print('Failed to create upload policy: ${uploadPolicyResponse.statusCode}');
      print(uploadPolicyResponse.body);
    }
    
    // Allow anyone to read/view the files
    final downloadPolicyResponse = await http.post(
      Uri.parse(policiesUrl),
      headers: headers,
      body: jsonEncode({
        'name': 'allow public downloads',
        'definition': {
          'role_id': 'anon',
          'operations': ['SELECT'],
        },
      }),
    );
    
    if (downloadPolicyResponse.statusCode == 200 || downloadPolicyResponse.statusCode == 201) {
      print('Download policy created successfully!');
    } else if (downloadPolicyResponse.statusCode == 409) {
      print('Download policy already exists.');
    } else {
      print('Failed to create download policy: ${downloadPolicyResponse.statusCode}');
      print(downloadPolicyResponse.body);
    }
    
    print('Setup complete.');
  } catch (e) {
    print('Error: $e');
  }
} 