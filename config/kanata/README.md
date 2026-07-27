# Kanata keyboard configuration

This directory keeps separate Kanata instances for the Framework keyboard and
external keyboards:

- `internal.kbd` targets the Framework keyboard by stable `/dev/input/by-id`
  paths.
- `external.kbd` allow-lists the external Apple keyboards by input-device name.
- `common.kbd` contains the shared home-row modifiers and layer controls.

All device names selected by `external.kbd` use the same source and layer
mapping. Kanata does not apply different mappings to individual devices in that
allow-list.

## Apple modifier-key diagnosis

Two physically similar Apple Magic Keyboards reached Kanata with different
modifier keycodes:

| Keyboard | Connection and product ID | Kernel behavior |
| --- | --- | --- |
| Magic Keyboard 2015 | Bluetooth `004C:0267` | Applied the `hid_apple` translations |
| Magic Keyboard with Touch ID | USB `05AC:029A` | Disabled the `hid_apple` translations |

The system had an untracked, manually created file at
`/etc/modprobe.d/hid_apple.conf` containing:

```conf
options hid_apple swap_opt_cmd=1
```

This was a hidden remapping layer before Kanata. For the older Bluetooth
keyboard, the kernel swapped Option/Command and the committed Kanata mapping
swapped them a second time. For the Touch ID keyboard, the journal contained:

```text
Fn key not found (Apple Wireless Keyboard clone?), disabling Fn key handling
```

In Linux's `hid-apple` driver, `swap_opt_cmd` and automatic ISO translation are
executed through the same event path as Fn handling. Clearing the
`APPLE_HAS_FN` flag therefore also bypassed those translations. The Touch ID
keyboard reached Kanata without the kernel swap, so Kanata's additional swap
made Command and Option incorrect.

The keyboards have the same physical modifier layout; the difference came from
the kernel event pipeline, not the keycaps.

## Chosen ownership boundary

Kanata now owns the keyboard-layout remapping. On 2026-07-27, the system file
was changed to disable the overlapping kernel translations:

```conf
options hid_apple swap_opt_cmd=0 iso_layout=0
```

`swap_opt_cmd=0` leaves Option and Command as reported by the keyboard.
`iso_layout=0` prevents the kernel from also swapping grave and the ISO key;
`external.kbd` owns that swap explicitly.

The previous system configuration is backed up at:

```text
/etc/modprobe.d/hid_apple.conf.bak-20260727
```

The initramfs was regenerated with:

```bash
sudo mkinitcpio -P
```

The `modconf` mkinitcpio hook embeds `/etc/modprobe.d/hid_apple.conf` in the
initramfs.

## Verification

When an Apple keyboard is connected and `hid_apple` is loaded:

```bash
cat /sys/module/hid_apple/parameters/swap_opt_cmd
cat /sys/module/hid_apple/parameters/iso_layout
```

Both should print `0`. To inspect the physical events before Kanata remaps them:

```bash
sudo systemctl stop kanata-external.service
sudo evtest
sudo systemctl start kanata-external.service
```

Select the real keyboard endpoint in `evtest`. Option should report
`KEY_LEFTALT`/`KEY_RIGHTALT`; Command should report
`KEY_LEFTMETA`/`KEY_RIGHTMETA`.

The Touch ID keyboard exposes another endpoint under the same name with a
permanently pressed `BTN_0`. Kanata 1.12 or newer is required so this endpoint
causes a bounded warning rather than a CPU busy-spin.

## Rollback

Restore the previous kernel swap and regenerate the initramfs:

```bash
sudo cp -a /etc/modprobe.d/hid_apple.conf.bak-20260727 \
  /etc/modprobe.d/hid_apple.conf
sudo mkinitcpio -P
```

Then reboot, or disconnect all Apple keyboards and reload `hid_apple` before
reconnecting them. The Kanata modifier mapping must also be restored if the
kernel once again owns the swap.
