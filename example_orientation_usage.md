# Funcionalidade de Rotação de Tela - ScoreboardScreen

## Implementação Concluída

A funcionalidade de rotação de tela foi implementada com sucesso na tela de placar (`ScoreboardScreen`). Agora os usuários podem:

### Funcionalidades Implementadas

1. **Rotação Automática**: A tela detecta automaticamente a orientação do dispositivo e adapta o layout
2. **Controles Manuais**: Botões para forçar orientação específica
3. **Bloqueio de Orientação**: Opção para bloquear a orientação atual
4. **Layouts Otimizados**: Diferentes layouts para retrato e paisagem

### Controles de Orientação

Na tela de placar, você encontrará três botões no canto superior esquerdo:

- **📱 Modo Retrato**: Força a orientação vertical
- **📱 Modo Paisagem**: Força a orientação horizontal  
- **🔄 Bloquear/Desbloquear**: Alterna entre rotação livre e bloqueada

### Diferenças entre os Layouts

#### Modo Retrato
- Times dispostos verticalmente (um acima do outro)
- Fonte do placar: 120px
- Nome do time: 32px
- Emoji/imagem: 48px/80px

#### Modo Paisagem
- Times dispostos horizontalmente (lado a lado)
- Fonte do placar: 100px (otimizada para largura)
- Nome do time: 28px
- Emoji/imagem: 40px/60px
- Timer posicionado mais abaixo para não sobrepor controles

### Como Usar

1. **Rotação Livre**: Por padrão, a tela permite rotação livre
2. **Forçar Orientação**: Toque no ícone de retrato ou paisagem
3. **Bloquear Orientação**: Toque no ícone de rotação para bloquear na orientação atual
4. **Desbloquear**: Toque novamente no ícone de bloqueio para permitir rotação livre

### Benefícios

- **Melhor Experiência**: Usuários podem escolher a orientação preferida
- **Flexibilidade**: Adaptação automática ou controle manual
- **Otimização**: Layouts específicos para cada orientação
- **Usabilidade**: Controles intuitivos e acessíveis

### Implementação Técnica

- Uso do `SystemChrome.setPreferredOrientations()` para controle de orientação
- Detecção de orientação com `MediaQuery.of(context).orientation`
- Layouts responsivos com tamanhos adaptativos
- Estado persistente dos controles de orientação

A implementação garante que a experiência do usuário seja otimizada tanto em modo retrato quanto paisagem, com controles fáceis de usar para personalizar a orientação conforme necessário.
