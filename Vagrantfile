# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Base box: Ubuntu 22.04 LTS (Jammy Jellyfish)
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_version = ">= 0"

  # VM hostname
  config.vm.hostname = "suri-caldera-lab"

  # ── Network ──────────────────────────────────────────────────────────────────
  # Private network so host can reach the VM directly
  config.vm.network "private_network", ip: "192.168.56.10"

  # Forwarded ports (host → guest)
  # Caldera web interface
  config.vm.network "forwarded_port", guest: 8888, host: 18888
  # Jupyter notebook
  config.vm.network "forwarded_port", guest: 8889, host: 8889
  # SSH explicit mapping (host 2223 -> guest 22)
  config.vm.network "forwarded_port", guest: 22,   host: 2223, id: "ssh"
  # Optional: Suricata API / EVE-JSON socket
  config.vm.network "forwarded_port", guest: 5000, host: 5000

  # ── Shared folder ─────────────────────────────────────────────────────────────
  config.vm.synced_folder ".", "/vagrant", type: "rsync"

  # ── VirtualBox provider ──────────────────────────────────────────────────────
  config.vm.provider "virtualbox" do |vb|
    vb.name   = "SURI-CALDERA-IDS-LAB"
    vb.memory = 4096
    vb.cpus   = 2
    vb.gui    = false

    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
    vb.customize ["modifyvm", :id, "--vram", "16"]
  end

  # ── VMware Desktop provider ──────────────────────────────────────────────────
  config.vm.provider "vmware_desktop" do |vmware|
    vmware.vmx["memsize"] = "4096"
    vmware.vmx["numvcpus"] = "2"
  end

  # ── Disk resize (optional plugin) ────────────────────────────────────────────
  if Vagrant.has_plugin?("vagrant-disksize")
    config.disksize.size = "20GB"
  end

  # ── Provisioning ─────────────────────────────────────────────────────────────
  config.vm.provision "file",
    source:      "vagrant/config",
    destination: "/tmp/config"

  config.vm.provision "file",
    source:      "vagrant/scripts",
    destination: "/tmp/scripts"

  config.vm.provision "file",
    source:      "notebooks",
    destination: "/tmp/notebooks"

  # Main provisioning shell script
  config.vm.provision "shell",
    path:       "vagrant/provision.sh",
    privileged: true

  # ── Post-provision message ────────────────────────────────────────────────────
  config.vm.post_up_message = <<~MSG
    ╔══════════════════════════════════════════════════════════════╗
    ║          SURI-CALDERA IDS PRACTICE LAB - READY!             ║
    ╠══════════════════════════════════════════════════════════════╣
    ║  Caldera  → http://localhost:18888                          ║
    ║             user: admin  /  password: admin                 ║
    ║  Jupyter  → http://localhost:8889                           ║
    ║  SSH      → vagrant ssh  (or ssh -p 2223 vagrant@127.0.0.1) ║
    ╠══════════════════════════════════════════════════════════════╣
    ║  Service commands (inside VM):                              ║
    ║    sudo systemctl status  caldera                           ║
    ║    sudo systemctl status  suricata                          ║
    ║    sudo systemctl status  jupyter                           ║
    ╠══════════════════════════════════════════════════════════════╣
    ║  Health check:  sudo /opt/scripts/check_services.sh         ║
    ╚══════════════════════════════════════════════════════════════╝
  MSG
end
