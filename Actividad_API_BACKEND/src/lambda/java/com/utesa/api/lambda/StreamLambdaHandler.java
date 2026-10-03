package com.utesa.api.lambda;

import com.amazonaws.serverless.exceptions.ContainerInitializationException;
import com.amazonaws.serverless.proxy.model.AwsProxyResponse;
import com.amazonaws.serverless.proxy.model.HttpApiV2ProxyRequest;
import com.amazonaws.serverless.proxy.spring.SpringBootLambdaContainerHandler;
import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestStreamHandler;
import com.utesa.api.ApiApplication;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

/**
 * Punto de entrada de AWS Lambda. API Gateway (HTTP API, payload 2.0) invoca este
 * handler y el contenedor traduce el evento a una peticion HTTP que procesa Spring MVC,
 * asi los controllers, el filtro JWT y Spring Security funcionan igual que en local.
 *
 * Spring Boot se inicializa en el bloque static: con SnapStart esto ocurre una sola vez
 * al publicar la version, y las invocaciones arrancan desde el snapshot ya inicializado.
 */
public class StreamLambdaHandler implements RequestStreamHandler {

    private static final SpringBootLambdaContainerHandler<HttpApiV2ProxyRequest, AwsProxyResponse> handler;

    static {
        try {
            handler = SpringBootLambdaContainerHandler.getHttpApiV2ProxyHandler(ApiApplication.class);
        } catch (ContainerInitializationException e) {
            throw new RuntimeException("No se pudo inicializar Spring Boot", e);
        }
    }

    @Override
    public void handleRequest(InputStream input, OutputStream output, Context context) throws IOException {
        handler.proxyStream(input, output, context);
    }
}
