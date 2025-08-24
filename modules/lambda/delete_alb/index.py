import boto3

def lambda_handler(event, context):
    client = boto3.client('elbv2')
    
    # Récupérer tous les ALBs
    response = client.describe_load_balancers()
    load_balancers = response['LoadBalancers']
    
    for alb in load_balancers:
        alb_arn = alb['LoadBalancerArn']
        alb_name = alb['LoadBalancerName']
        print(f"Suppression de l'ALB: {alb_name} ({alb_arn})")
        
        # Récupérer et supprimer les listeners
        listeners = client.describe_listeners(LoadBalancerArn=alb_arn)['Listeners']
        for listener in listeners:
            listener_arn = listener['ListenerArn']
            print(f"  - Suppression du listener {listener_arn}")
            client.delete_listener(ListenerArn=listener_arn)
        
        # Supprimer l'ALB
        client.delete_load_balancer(LoadBalancerArn=alb_arn)
    
    return {
        'statusCode': 200,
        'body': f"{len(load_balancers)} ALBs supprimés"
    }