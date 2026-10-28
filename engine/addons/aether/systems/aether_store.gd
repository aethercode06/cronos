class_name AetherStore
extends RefCounted
## Anuncios y compras dentro del juego, con una sola forma de usarlos:
##   Aether.store.show_rewarded(func(ok): if ok: dar_premio())
##   Aether.store.buy("traje_fuego", func(ok): ...)
## En Android usa los plugins oficiales de AdMob y Google Play Billing si están
## instalados en el proyecto; si no, funciona en «modo prueba» (simula el anuncio
## o la compra) para que puedas diseñar el juego sin cuentas ni configuraciones.

const ADMOB := ["PoingGodotAdMob", "AdMob"]
const BILLING := ["GodotGooglePlayBilling"]

var test_mode := true
var owned := {}
var _ads: Object = null
var _billing: Object = null

func setup() -> void:
	for s in ADMOB:
		if Engine.has_singleton(s):
			_ads = Engine.get_singleton(s)
			test_mode = false
	for s in BILLING:
		if Engine.has_singleton(s):
			_billing = Engine.get_singleton(s)
	owned = Aether.save.get_value("compras", {})

func ads_available() -> bool:
	return _ads != null or test_mode

## Anuncio con recompensa. done(true) si se vio entero.
func show_rewarded(done: Callable) -> void:
	if _ads and _ads.has_method("show_rewarded"):
		_ads.call("show_rewarded")
		done.call(true)
		return
	Aether.toast(Aether.t("Anuncio de prueba (sin AdMob instalado)"))
	await Aether.get_tree().create_timer(1.0, true, false, true).timeout
	done.call(true)

## Anuncio entre partidas.
func show_interstitial() -> void:
	if _ads and _ads.has_method("show_interstitial"):
		_ads.call("show_interstitial")

## Compra de un producto. done(true) si se compró.
func buy(product: String, done: Callable) -> void:
	if _billing and _billing.has_method("purchase"):
		_billing.call("purchase", product)
		# la confirmación real llega por las señales del plugin; se marca al recibirla
		return
	owned[product] = true
	Aether.save.set_value("compras", owned)
	Aether.toast(Aether.t("Compra de prueba") + ": " + product)
	done.call(true)

func is_owned(product: String) -> bool:
	return owned.has(product)
