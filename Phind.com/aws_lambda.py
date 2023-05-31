import boto3
import json

s3_client = boto3.client('s3')
rekognition_client = boto3.client('rekognition')

def lambda_handler(event, context):
    # Get the bucket name and file name from the input event
    bucket_name = event['bucket_name']
    file_name = event['file_name']
    
    # Download the mp4 file from S3
    s3_client.download_file(bucket_name, file_name, '/tmp/input.mp4')
    
    # Use Amazon Rekognition Video to detect license plates in the video
    response = rekognition_client.start_text_detection(
        Video={
            'S3Object': {
                'Bucket': bucket_name,
                'Name': file_name
            }
        }
    )
    
    # Extract the license plate numbers and timestamps from the response
    plates = {}
    for item in response['TextDetections']:
        if item['Type'] == 'LINE' and item['DetectedText'].isalnum() and len(item['DetectedText']) == 6:
            plate_number = item['DetectedText']
            timestamp = item['Timestamp']
            if plate_number not in plates:
                plates[plate_number] = []
            plates[plate_number].append(timestamp)
    
    # Store the extracted data in a JSON file
    output = {'plates': plates}
    with open('/tmp/output.json', 'w') as f:
        json.dump(output, f)
    
    # Upload the JSON file back to S3
    s3_client.upload_file('/tmp/output.json', bucket_name, 'output.json')
