<div align="center">

# Solter AI

<p align="center">
  <b>The autonomous voice agent that answers questions and takes action on real-time.</b><br/>
  Voice Agent • Real-Time Action • RAG • MCP
</p>

[![License: Proprietary](https://img.shields.io/badge/License-Proprietary-blue.svg?style=for-the-badge)](LICENSE)
[![Architecture: Event-Driven](https://img.shields.io/badge/Architecture-Event--Driven%20Microservices-8A2BE2?style=for-the-badge&logo=apachekafka)](https://github.com/Solter-AI)
[![Status: In Active Development](https://img.shields.io/badge/Status-Phase%201%20MVP-brightgreen?style=for-the-badge)](https://github.com/Solter-AI)


<br/>

</div>

---

## System Architecture

```mermaid
flowchart TB
    %% External Actors & Telephony
    subgraph External ["External Ecosystem"]
        PSTN["End Customer<br/>(PSTN / Mobile Phone)"]
        Telephony["Telephony Providers<br/>(Exotel / Plivo / Twilio)"]
        ClientBackend["Tenant Backend Systems<br/>(e.g., NoBroker APIs & Webhooks)"]
        TenantAdmin["Company Admin<br/>(Browser / Dashboard)"]
    end

    %% Edge / Ingress
    subgraph Edge ["Edge & Media Ingress"]
        APIGW["solter-api-gateway<br/>(Spring Cloud Gateway | Auth & Rate Limit)"]
        TeleBridge["solter-telephony-bridge<br/>(SIP / WebSocket Bridge & Outbound Trigger)"]
        LiveKit["LiveKit Media Server<br/>(WebRTC & SIP Trunking | Sub-50ms Routing)"]
    end

    %% Real-Time Hot Path (Sub-600ms Budget)
    subgraph HotPath ["Real-Time Voice Hot Path (Target < 600ms Turn-Around)"]
        VoiceOrch["solter-voice-orchestrator<br/>(Python / Pipecat Worker | Silero VAD & Barge-In)"]
        
        subgraph AIProviders ["Streaming AI Inference Providers"]
            STT["Streaming STT<br/>(Deepgram Nova-3 / Sarvam AI)"]
            LLM["Low-Latency LLM<br/>(Gemini 2.5 Flash / GPT-4o-mini)"]
            TTS["Streaming TTS<br/>(Cartesia Sonic-2 / ElevenLabs Flash)"]
        end

        RAG["solter-rag-service<br/>(Python gRPC | Hybrid Search < 50ms)"]
        MCPGW["solter-mcp-gateway<br/>(Java 21 Virtual Threads | OpenAPI-to-MCP & Validator)"]
    end

    %% Control Plane & Async Cold Path
    subgraph ControlCold ["Control Plane & Async Cold Path"]
        WebUI["solter-web<br/>(React / Redux Dashboard)"]
        TenantSvc["solter-tenant-service<br/>(Spring Boot | Tenant Configs, Agents & RBAC)"]
        AnalyticsSvc["solter-analytics-service<br/>(Spring Boot | Transcripts, Audio & QA Logs)"]
        BillingSvc["solter-billing-service<br/>(Spring Boot | Usage Metering & Invoicing)"]
    end

    %% State, Storage & Event Backbone
    subgraph DataLayer ["Data, State & Security Backbone"]
        Redis[("Redis Cluster<br/>(Live Call Session State & Pre-Fetched Context)")]
        Kafka{{"Apache Kafka<br/>(CallCompleted & ToolExecuted Events)"}}
        Postgres[("PostgreSQL 16 + pgvector<br/>(Multi-Tenant Metadata, Logs & Vector Embeddings)")]
        Vault["Secrets Vault<br/>(AWS Secrets Manager / HashiCorp Vault)"]
        S3[("Object Storage (S3)<br/>(Call Recordings & Uploaded Docs)")]
    end

    %% Connections - Telephony & Live Audio
    PSTN <-->|"PSTN Voice"| Telephony
    Telephony <-->|"SIP / RTP Audio"| LiveKit
    ClientBackend -->|"POST /v1/calls/outbound"| APIGW
    APIGW --> TeleBridge
    TeleBridge -->|"1. Warm Call Context"| Redis
    TeleBridge -->|"2. Dial & Join Room"| LiveKit
    LiveKit <-->|"WebRTC Raw PCM Audio"| VoiceOrch

    %% Connections - Hot Path AI & Tools
    VoiceOrch <-->|"Audio Stream"| STT
    VoiceOrch <-->|"Streaming Tokens & Tool Calls"| LLM
    VoiceOrch <-->|"Streaming Audio Chunks"| TTS
    VoiceOrch <-->|"Read/Write Turn State"| Redis
    VoiceOrch <-->|"gRPC (< 50ms)"| RAG
    VoiceOrch <-->|"gRPC / HTTP2 + Scoped JWT"| MCPGW

    %% Connections - Security & External API Execution
    MCPGW -.->|"Fetch Decrypted API Key"| Vault
    MCPGW <-->|"HTTPS + Injected Auth Header"| ClientBackend
    RAG <-->|"Vector + Keyword Query"| Postgres

    %% Connections - Control Plane & Dashboard
    TenantAdmin --> WebUI
    WebUI --> APIGW
    APIGW --> TenantSvc
    APIGW --> AnalyticsSvc
    APIGW --> BillingSvc
    TenantSvc <--> Postgres
    TenantSvc -->|"Store Encrypted Secrets"| Vault
    TenantSvc -->|"Upload Docs / OpenAPI Specs"| S3
    S3 -.->|"Async Indexing"| RAG
    S3 -.->|"Compile & Register Tools"| MCPGW

    %% Connections - Async Event Pipeline
    VoiceOrch -->|"Publish Call & Tool Events"| Kafka
    MCPGW -->|"Publish Tool Audit Events"| Kafka
    LiveKit -.->|"Save Call Recording"| S3
    Kafka --> AnalyticsSvc
    Kafka --> BillingSvc
    AnalyticsSvc --> Postgres
    BillingSvc --> Postgres

    %% Styling
    classDef hot fill:#1e1b4b,stroke:#6366f1,stroke-width:2px,color:#ffffff;
    classDef control fill:#0f172a,stroke:#38bdf8,stroke-width:1.5px,color:#ffffff;
    classDef data fill:#14532d,stroke:#22c55e,stroke-width:1.5px,color:#ffffff;
    classDef external fill:#27272a,stroke:#a1a1aa,stroke-width:1.5px,color:#ffffff;

    class VoiceOrch,STT,LLM,TTS,RAG,MCPGW,LiveKit hot;
    class WebUI,APIGW,TeleBridge,TenantSvc,AnalyticsSvc,BillingSvc control;
    class Redis,Kafka,Postgres,Vault,S3 data;
    class PSTN,Telephony,ClientBackend,TenantAdmin external;
```


---

## Contributing

Repositories are currently private, but I am actively seeking collaborators to help build Solter AI. If you would like to contribute for Solter AI, please reach out to me via [LinkedIn](https://www.linkedin.com/in/dharmarajrathinavel/). 


![](./.assets/Banner.png)

<!-- 
<div align="center">
  <p>Built with ❤️ by <b><a href="https://dharmaraj-rathinavel.work/">Dharmaraj</a></b></p>
</div> -->
