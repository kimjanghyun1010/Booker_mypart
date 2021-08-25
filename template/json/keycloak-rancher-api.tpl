{
{{- if .global.port.rancher_https }}
        "clientId": "https://{{ .rancher.cname }}.{{ .global.domain }}:{{ .global.port.rancher_https }}/v1-saml/keycloak/saml/metadata",
{{ else }}
        "clientId": "https://{{ .rancher.cname }}.{{ .global.domain }}/v1-saml/keycloak/saml/metadata",
{{- end }}
    "surrogateAuthRequired": false,
    "enabled": true,
    "alwaysDisplayInConsole": false,
    "clientAuthenticatorType": "client-secret",
    "redirectUris": [
{{- if .global.port.rancher_https }}
        "https://{{ .rancher.cname }}.{{ .global.domain }}:{{ .global.port.rancher_https }}/v1-saml/keycloak/saml/acs"
{{ else }}
        "https://{{ .rancher.cname }}.{{ .global.domain }}/v1-saml/keycloak/saml/acs"
{{- end }}
    ],
    "webOrigins": [],
    "notBefore": 0,
    "bearerOnly": false,
    "consentRequired": false,
    "standardFlowEnabled": true,
    "implicitFlowEnabled": false,
    "directAccessGrantsEnabled": false,
    "serviceAccountsEnabled": false,
    "publicClient": false,
    "frontchannelLogout": false,
    "protocol": "saml",
    "attributes": {
        "saml.assertion.signature": "true",
        "saml.force.post.binding": "false",
        "saml.multivalued.roles": "false",
        "saml.encrypt": "false",
        "saml.server.signature": "true",
        "saml.server.signature.keyinfo.ext": "false",
        "exclude.session.state.from.auth.response": "false",
        "saml.signature.algorithm": "RSA_SHA256",
        "saml_force_name_id_format": "false",
        "saml.client.signature": "false",
        "tls.client.certificate.bound.access.tokens": "false",
        "saml.authnstatement": "false",
        "display.on.consent.screen": "false",
        "saml_name_id_format": "username",
        "saml.onetimeuse.condition": "false",
        "saml_signature_canonicalization_method": "http://www.w3.org/2001/10/xml-exc-c14n#"
    },
    "authenticationFlowBindingOverrides": {},
    "fullScopeAllowed": true,
    "nodeReRegistrationTimeout": -1,
    "protocolMappers": [
        {
            "name": "username to cn",
            "protocol": "saml",
            "protocolMapper": "saml-user-property-mapper",
            "consentRequired": false,
            "config": {
                "user.attribute": "username",
                "attribute.name": "cn"
            }
        },
        {
            "name": "username to uid",
            "protocol": "saml",
            "protocolMapper": "saml-user-property-mapper",
            "consentRequired": false,
            "config": {
                "user.attribute": "username",
                "attribute.name": "uid"
            }
        },
        {
            "name": "fullName to displayName",
            "protocol": "saml",
            "protocolMapper": "saml-user-property-mapper",
            "consentRequired": false,
            "config": {
                "user.attribute": "fullName",
                "attribute.name": "displayName"
            }
        },
        {
            "name": "group",
            "protocol": "saml",
            "protocolMapper": "saml-group-membership-mapper",
            "consentRequired": false,
            "config": {
                "single": "true",
                "full.path": "true",
                "attribute.name": "member"
            }
        }
    ],
    "defaultClientScopes": [
        "web-origins",
        "role_list",
        "roles",
        "profile",
        "email"
    ],
    "optionalClientScopes": [
        "address",
        "phone",
        "offline_access",
        "microprofile-jwt"
    ],
    "access": {
        "view": true,
        "configure": true,
        "manage": true
    }
}
