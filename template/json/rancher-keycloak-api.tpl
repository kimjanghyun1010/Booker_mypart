<EntityDescriptor entityID="https://{{ .keycloak.ingress.cname }}.{{ .global.domain }}/auth/realms/paasxpert" Name="urn:keycloak" xmlns="urn:oasis:names:tc:SAML:2.0:metadata"
					xmlns:dsig="http://www.w3.org/2000/09/xmldsig#">
		<IDPSSODescriptor WantAuthnRequestsSigned="true"
			protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
                        <KeyDescriptor use="signing">
                          <dsig:KeyInfo>
                            <dsig:KeyName>KID</dsig:KeyName>
                            <dsig:X509Data>
                              <dsig:X509Certificate>PAASXPERT_CERTIFIATE</dsig:X509Certificate>
                            </dsig:X509Data>
                          </dsig:KeyInfo>
                        </KeyDescriptor>

			<SingleLogoutService
					Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
					Location="https://{{ .keycloak.ingress.cname }}.{{ .global.domain }}/auth/realms/paasxpert/protocol/saml" />
			<SingleLogoutService
					Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
					Location="https://{{ .keycloak.ingress.cname }}.{{ .global.domain }}/auth/realms/paasxpert/protocol/saml" />
			<NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:persistent</NameIDFormat>
			<NameIDFormat>urn:oasis:names:tc:SAML:2.0:nameid-format:transient</NameIDFormat>
			<NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified</NameIDFormat>
			<NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</NameIDFormat>
			<SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
				Location="https://{{ .keycloak.ingress.cname }}.{{ .global.domain }}/auth/realms/paasxpert/protocol/saml" />
			<SingleSignOnService
				Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
				Location="https://{{ .keycloak.ingress.cname }}.{{ .global.domain }}/auth/realms/paasxpert/protocol/saml" />
			<SingleSignOnService
				Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
				Location="https://{{ .keycloak.ingress.cname }}.{{ .global.domain }}/auth/realms/paasxpert/protocol/saml" />
		</IDPSSODescriptor>
	</EntityDescriptor>
