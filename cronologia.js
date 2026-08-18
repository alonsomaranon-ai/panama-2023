/* Dos cosas hace este archivo, y nada más:
   1. El buscador que filtra los 45 días por palabra.
   2. El índice lateral que marca en qué día estás parado al scrollear.
   Si borrás este archivo, la página sigue funcionando: solo se pierden
   esas dos comodidades. Nada del informe depende de acá.            */

(function () {
  'use strict';

  var dias  = Array.prototype.slice.call(document.querySelectorAll('.dia'));
  var input = document.getElementById('q');
  var salida = document.getElementById('resultado');

  /* ---------- 1. Buscador ---------- */

  if (input && dias.length) {

    // guardo el texto original de cada día para poder restaurarlo
    dias.forEach(function (dia) {
      dia.dataset.texto = dia.textContent.toLowerCase();
      dia.dataset.original = dia.querySelector('.dia-texto').innerHTML;
    });

    // el buscador NO esconde días: la cronología queda entera y lo que
    // hace es marcar dónde aparece el término. Así se ve la distribución
    // en el tiempo —cuándo entra un actor en escena y cuándo desaparece—
    // que en un informe de eventos dice tanto como el dato mismo.
    var buscar = function () {
      var q = input.value.trim().toLowerCase();

      var limpiar = function () {
        dias.forEach(function (dia) {
          dia.querySelector('.dia-texto').innerHTML = dia.dataset.original;
        });
        document.querySelectorAll('.riel a').forEach(function (a) {
          a.classList.remove('coincide');
        });
      };

      if (q.length < 2) { limpiar(); salida.textContent = ''; return; }

      limpiar();

      var re = new RegExp('(' + q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + ')(?![^<]*>)', 'gi');
      var conCoincidencia = [];

      dias.forEach(function (dia) {
        if (dia.dataset.texto.indexOf(q) === -1) { return; }
        conCoincidencia.push(dia);
        dia.querySelector('.dia-texto').innerHTML = dia.dataset.original.replace(re, '<mark>$1</mark>');
        var enlace = document.querySelector('.riel a[href="#' + dia.id + '"]');
        if (enlace) { enlace.classList.add('coincide'); }
      });

      var termino = input.value.trim();

      if (conCoincidencia.length === 0) {
        salida.textContent = 'Sin menciones de «' + termino + '» en los 45 días.';
        return;
      }

      // la lista de fechas: sirve en cualquier pantalla, y en celular es
      // lo único que hay, porque ahí el índice lateral no se muestra
      var lista = conCoincidencia.map(function (dia) {
        // el sello es "<b>20</b>oct": el número y el mes van pegados en el
        // HTML, así que los separo para que la lista se lea "20 oct"
        var sello = dia.querySelector('.sello');
        var numero = sello.querySelector('b').textContent.trim();
        var mes = sello.lastChild.textContent.trim();
        return '<a href="#' + dia.id + '">' + numero + ' ' + mes + '</a>';
      }).join(' · ');

      salida.innerHTML =
        '<b>' + conCoincidencia.length + '</b> de 43 días mencionan «' + termino + '»: ' + lista;
    };

    input.addEventListener('input', buscar);
  }

  /* ---------- 2. Índice lateral ---------- */

  var enlaces = document.querySelectorAll('.riel a');
  if (!enlaces.length || !('IntersectionObserver' in window)) { return; }

  var porId = {};
  enlaces.forEach(function (a) { porId[a.getAttribute('href').slice(1)] = a; });

  var observador = new IntersectionObserver(function (entradas) {
    entradas.forEach(function (e) {
      var a = porId[e.target.id];
      if (!a) { return; }
      if (e.isIntersecting) {
        enlaces.forEach(function (x) { x.classList.remove('activo'); });
        a.classList.add('activo');
        // acompaño el scroll del índice para que el día activo quede a la vista
        var riel = a.parentElement;
        if (a.offsetTop < riel.scrollTop || a.offsetTop > riel.scrollTop + riel.clientHeight - 30) {
          riel.scrollTop = a.offsetTop - riel.clientHeight / 2;
        }
      }
    });
  }, { rootMargin: '-15% 0px -70% 0px' });

  dias.forEach(function (dia) { observador.observe(dia); });

})();
