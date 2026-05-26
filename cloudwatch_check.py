import boto3
from datetime import datetime, timedelta, timezone

cw = boto3.client('cloudwatch', region_name='ap-south-1')

# Active alarms check karo
response = cw.describe_alarms(StateValue='ALARM')

if not response['MetricAlarms']:
    print('All clear — koi active alarm nahi!')
else:
    for alarm in response['MetricAlarms']:
        print(f'ALARM: {alarm["AlarmName"]} — {alarm["StateReason"][:60]}')

# python3 cloudwatch_check.py