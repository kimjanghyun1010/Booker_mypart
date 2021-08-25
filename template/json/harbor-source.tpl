{
  "auth_mode": "oidc_auth",
  "oidc_client_id": "harbor",
  "oidc_endpoint": "https://{{ .keycloak.ingress.cname }}.{{ .global.domain }}/auth/realms/paasxpert",
  "oidc_groups_claim": "group-membership",
  "oidc_name": "keycloak",
  "oidc_scope": "openid,offline_access",
  "oidc_verify_cert": false,
  "oidc_client_secret": "HARBOR_SECRET",
  "oidc_auto_onboard": "true",
  "oidc_user_claim": "preferred_username"
}
