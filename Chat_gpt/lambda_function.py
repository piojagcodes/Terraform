import boto3

def lambda_handler(event, context):
    # Pobranie danych wejściowych
    bucket_name = event['bucket_name']
    file_name = event['file_name']

    # Inicjalizacja klienta S3 i Rekognition
    s3_client = boto3.client('s3')
    rekognition_client = boto3.client('rekognition')

    # Pobranie pliku MP4 z S3
    response = s3_client.get_object(Bucket=bucket_name, Key=file_name)
    video_bytes = response['Body'].read()

    # Wykrywanie tekstu na filmie
    response = rekognition_client.start_text_detection(
        Video={
            'S3Object': {
                'Bucket': bucket_name,
                'Name': file_name
            }
        }
    )
    job_id = response['JobId']

    # Pobranie wyników przetwarzania
    response = rekognition_client.get_text_detection(JobId=job_id)
    text_detections = response['TextDetections']

    # Przetworzenie wyników i zapisanie ich do S3
    results = process_text_detections(text_detections)
    output_file_name = 'output.json'
    s3_client.put_object(Body=str(results), Bucket=bucket_name, Key=output_file_name)

    return {
        'statusCode': 200,
        'body': 'Przetwarzanie zakończone. Wyniki zapisane w pliku {}'.format(output_file_name)
    }

def process_text_detections(text_detections):
    # Przetwarzanie wyników wykrywania tekstu i zwracanie listy tablic rejestracyjnych wraz z czasem wystąpienia
    results = {}
    for detection in text_detections:
        if detection['Type'] == 'LINE' and detection['Confidence'] > 90:
            license_plate = detection['DetectedText']
            timestamp = detection['Timestamp']
            if license_plate not in results:
                results[license_plate] = []
            results[license_plate].append(timestamp)

    return results
