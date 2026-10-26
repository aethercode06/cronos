// Textos añadidos después (estrellas y Torre del Tiempo)
(function () {
  const ES = ['Superada', 'Sin caer', 'Fragmentos ≥ 80 %', 'Tiempo ≤ ', 'Récord de la Torre: piso ', 'Vence al primer guardián para abrir la Torre', 'TORRE', 'TORRE DEL TIEMPO',
    '¡GUARDIÁN DE LA TORRE!  ·  ', 'PISO ', 'Piso alcanzado: ', 'REINTENTAR TORRE', '+25 vida', 'Coleccionista de estrellas', 'Consigue 42 estrellas', 'Perfección temporal',
    'Consigue las 126 estrellas', 'Escalador del tiempo', 'Llega al piso 10 de la Torre', 'Señor de la Torre', 'Llega al piso 25 de la Torre'];
  const X = {
    en: ['Cleared', 'No falls', 'Fragments ≥ 80%', 'Time ≤ ', 'Tower record: floor ', 'Defeat the first guardian to open the Tower', 'TOWER', 'TOWER OF TIME',
      'TOWER GUARDIAN!  ·  ', 'FLOOR ', 'Floor reached: ', 'RETRY TOWER', '+25 HP', 'Star collector', 'Earn 42 stars', 'Temporal perfection',
      'Earn all 126 stars', 'Time climber', 'Reach floor 10 of the Tower', 'Lord of the Tower', 'Reach floor 25 of the Tower'],
    pt: ['Concluída', 'Sem cair', 'Fragmentos ≥ 80%', 'Tempo ≤ ', 'Recorde da Torre: andar ', 'Vença o primeiro guardião para abrir a Torre', 'TORRE', 'TORRE DO TEMPO',
      'GUARDIÃO DA TORRE!  ·  ', 'ANDAR ', 'Andar alcançado: ', 'TENTAR A TORRE DE NOVO', '+25 vida', 'Colecionador de estrelas', 'Consiga 42 estrelas', 'Perfeição temporal',
      'Consiga as 126 estrelas', 'Escalador do tempo', 'Chegue ao andar 10 da Torre', 'Senhor da Torre', 'Chegue ao andar 25 da Torre'],
    fr: ['Réussi', 'Sans chute', 'Fragments ≥ 80 %', 'Temps ≤ ', 'Record de la Tour : étage ', 'Bats le premier gardien pour ouvrir la Tour', 'TOUR', 'TOUR DU TEMPS',
      'GARDIEN DE LA TOUR !  ·  ', 'ÉTAGE ', 'Étage atteint : ', 'REJOUER LA TOUR', '+25 vie', 'Collectionneur d\'étoiles', 'Obtiens 42 étoiles', 'Perfection temporelle',
      'Obtiens les 126 étoiles', 'Grimpeur du temps', 'Atteins l\'étage 10 de la Tour', 'Seigneur de la Tour', 'Atteins l\'étage 25 de la Tour'],
    de: ['Geschafft', 'Ohne Sturz', 'Fragmente ≥ 80 %', 'Zeit ≤ ', 'Turmrekord: Etage ', 'Besiege den ersten Hüter, um den Turm zu öffnen', 'TURM', 'TURM DER ZEIT',
      'HÜTER DES TURMS!  ·  ', 'ETAGE ', 'Erreichte Etage: ', 'TURM NEU VERSUCHEN', '+25 Leben', 'Sternensammler', 'Sammle 42 Sterne', 'Zeitliche Perfektion',
      'Sammle alle 126 Sterne', 'Zeitkletterer', 'Erreiche Etage 10 des Turms', 'Herr des Turms', 'Erreiche Etage 25 des Turms'],
    it: ['Superato', 'Senza cadute', 'Frammenti ≥ 80%', 'Tempo ≤ ', 'Record della Torre: piano ', 'Sconfiggi il primo guardiano per aprire la Torre', 'TORRE', 'TORRE DEL TEMPO',
      'GUARDIANO DELLA TORRE!  ·  ', 'PIANO ', 'Piano raggiunto: ', 'RIPROVA LA TORRE', '+25 vita', 'Collezionista di stelle', 'Ottieni 42 stelle', 'Perfezione temporale',
      'Ottieni tutte le 126 stelle', 'Scalatore del tempo', 'Raggiungi il piano 10 della Torre', 'Signore della Torre', 'Raggiungi il piano 25 della Torre'],
    ja: ['クリア', 'ノーミス', '欠片 80%以上', 'タイム ≤ ', '塔の記録：', '最初の守護者を倒すと塔が開く', '塔', '時の塔',
      '塔の守護者！  ・  ', '階層 ', '到達階層：', '塔に再挑戦', 'HP+25', '星のコレクター', '星を42個集める', '完璧な時',
      '星を126個すべて集める', '時を登る者', '塔の10階に到達', '塔の覇者', '塔の25階に到達'],
    ko: ['클리어', '쓰러지지 않음', '조각 80% 이상', '시간 ≤ ', '탑 최고 기록: ', '첫 번째 수호자를 쓰러뜨리면 탑이 열린다', '탑', '시간의 탑',
      '탑의 수호자!  ·  ', '층 ', '도달한 층: ', '탑 재도전', '체력 +25', '별 수집가', '별 42개 모으기', '완벽한 시간',
      '별 126개 모두 모으기', '시간을 오르는 자', '탑 10층 도달', '탑의 지배자', '탑 25층 도달'],
    zh: ['通关', '未倒下', '碎片 ≥ 80%', '用时 ≤ ', '高塔纪录：第', '击败第一位守护者以开启高塔', '高塔', '时间之塔',
      '高塔守护者！  ·  ', '层数 ', '到达层数：', '重新挑战高塔', '+25 生命', '星星收藏家', '获得42颗星星', '完美时光',
      '获得全部126颗星星', '时间攀登者', '到达高塔第10层', '高塔之主', '到达高塔第25层']
  };
  for (let i = 0; i < ES.length; i++) { I18N_ES.push(ES[i]); for (const l in X) I18N[l].push(X[l][i]); }
})();
