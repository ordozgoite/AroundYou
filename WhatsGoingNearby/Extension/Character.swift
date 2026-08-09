//
//  Character.swift
//  WhatsGoingNearby
//
//  Created by Victor Ordozgoite on 27/04/24.
//

import Foundation

extension Character {

    /// Indica se o sistema desenha este `Character` como pictograma.
    ///
    /// A conta é feita sobre as propriedades Unicode dos scalars, e não sobre uma lista ou
    /// faixas de codepoints: emoji novos entram de graça a cada atualização da tabela do
    /// sistema. Um `Character` já é um grapheme cluster, então uma família inteira
    /// (👨‍👩‍👧‍👦), uma bandeira (🇧🇷) ou um emoji com tom de pele (👍🏽) chegam aqui como um
    /// único elemento, mesmo carregando vários scalars por dentro.
    var isEmoji: Bool {
        guard let first = unicodeScalars.first, first.properties.isEmoji else { return false }

        if unicodeScalars.count == 1 {
            // `isEmoji` sozinho é permissivo demais: dígitos, `#` e `*` o satisfazem porque
            // são a base dos keycaps (1️⃣). Isolados, continuam sendo texto comum — daí a
            // exigência de apresentação pictográfica por padrão (😀, ⌚) ou, no mínimo, de
            // não ser ASCII, o que preserva os símbolos que o iOS já desenha coloridos
            // mesmo sem seletor de variação (❤).
            return first.properties.isEmojiPresentation || !first.isASCII
        }

        // Numa sequência, o que decide é haver algo que force a leitura pictográfica do
        // conjunto. Sem isso, cair aqui só significa que o primeiro scalar é elegível a
        // emoji — o que também vale para um dígito seguido de acento combinante.
        return unicodeScalars.contains { scalar in
            scalar.properties.isEmojiPresentation   // base de ZWJ, bandeiras, keycap sobre emoji
            || scalar.properties.isEmojiModifier    // tom de pele
            || scalar.value == 0xFE0F               // variation selector-16
            || scalar.value == 0x20E3               // combining enclosing keycap
            || scalar.value == 0x200D               // zero width joiner
        }
    }
}
