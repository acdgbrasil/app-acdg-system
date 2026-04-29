# A10 — Web: Assessment (7 fichas)

## Onda: 3 | Profile: bff/social_care_web | Depende de: A06

## Escopo
Endpoints das 7 fichas de avaliação:
- `PUT /api/patients/:id/assessment/housing`
- `PUT /api/patients/:id/assessment/socioeconomic`
- `PUT /api/patients/:id/assessment/work-income`
- `PUT /api/patients/:id/assessment/education`
- `PUT /api/patients/:id/assessment/health`
- `PUT /api/patients/:id/assessment/community-support`
- `PUT /api/patients/:id/assessment/social-health-summary`

Cada um com Intent + UseCase consumindo `AssessmentContract`. Handler `AssessmentHandler` unificado.

## Critérios
- [ ] 7 endpoints funcionais
- [ ] 7 Intents + 7 UseCases (ou padrão unificado com variação por ficha)
- [ ] Zero `SocialCareContract`
- [ ] `dart analyze bff/social_care_web` verde

## Status
pending — blocked by A06
