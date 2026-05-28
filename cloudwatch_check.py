import boto3
from datetime import datetime, timedelta, timezone

cw = boto3.client('cloudwatch', region_name='ap-south-1')

# check for any alarms in the last 24 hours
response = cw.describe_alarms(StateValue='ALARM')

if not response['MetricAlarms']:
    print('All clear — no active alarms!')
else:
    for alarm in response['MetricAlarms']:
        print(f'ALARM: {alarm["AlarmName"]} — {alarm["StateReason"][:60]}')

# python3 cloudwatch_check.py