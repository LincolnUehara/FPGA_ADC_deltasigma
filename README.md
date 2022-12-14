# Projeto de ADC Delta-Sigma

Esse é um projeto para o curso "SEL5752 - Dispositivos Reconfiguráveis e Linguagem de Descrição de Hardware" ministrado pelo professor Maximiliam Luppe na USP São Carlos.

Os códigos foram modificados a partir do material fornecido pelo Lattice Semiconductor [neste link](https://www.latticesemi.com/products/designsoftwareandip/intellectualproperty/referencedesigns/referencedesign03/simplesigmadeltaadc).

### Utilização do Docker

Para facilitar a preparação do ambiente, utiliza-se do Docker e um script. A instalação do Docker no Ubuntu, por exemplo, pode ser vista [neste link](https://docs.docker.com/engine/install/ubuntu/)

1. Execute no diretório deste repositório os comandos abaixo para construir a imagem e rodar o container pela primeira vez:
``` 
~$ sudo docker build --build-arg host_uid=$(id -u) --build-arg host_gid=$(id -g) --tag "fpga-env-image" .
~$ sudo docker run -it --network host -v $PWD:/home/fpga/workspace -v /media:/media -v /dev:/dev -v /etc/udev/rules.d:/etc/udev/rules.d --privileged --env="DISPLAY" --name fpga-env fpga-env-image
```

2. Nas próximas vezes que for rodar o mesmo container, execute o comando abaixo (senha para usuário 'fpga' é 'fpga'):
```
~$ sudo docker start -i fpga-env
```

3. Comandos para limpar todos os containeres e imagens existentes:
```
~$ sudo docker container rm --force $(sudo docker container ls -a --quiet) ; sudo docker image rm --force $(sudo docker image ls -a --quiet)
```

4. Para instalar as ferrametas relacionadas a FPGA dentro do container, utilize o script:
```
~/workspace$ ./init-fpga-env -h

Syntax: init-fpga-env [-h|i|r]
options:
h          Print this help
i          Install all the necessary tools
r <TOOL>   Reinstall given TOOL. If "all" is given reinstalls all.
           Used in case docker container was removed and run again.

~/workspace$
```

### Comandos Octave

* Primeiramente instale as dependências do Octave:

```
~/workspace/src$ cd octave
~/workspace/src/octave$ octave pkg_install.m # Irá demorar um pouco
```

* Gere o arquivo *input.csv*:
```
~/workspace/src/octave$ octave gen_XXXX.m
```

* Para comparar o *input.csv* com *output.csv* (este gerado na execução do testbench como descrito no item seguinte), execute o comando:
```
~/workspace/src/octave$ octave --persist comp_waves.m # Ctrl-D para sair
```

### Comandos para síntese em GHDL

* Primeiramente faça a análise das bibliotecas.

```
~/workspace$ cd src
~/workspace/src$ ghdl -a -fexplicit -fsynopsys --std=08 \
                      pkg_adc/custom_adc_filter.vhd \
                      pkg_adc/custom_adc_filter-body.vhd \
                      pkg_adc/custom_adc.vhd \
                      pkg_adc/custom_adc-body.vhd \
                      pkg_tb/custom_tb.vhd \
                      pkg_tb/custom_tb-body.vhd
```

* Para analisar, elaborar e executar ADC_tf (exemplo do Lattice Semiconductor), digite os seguinte comandos:

```
~/workspace/src$ ghdl -a -fexplicit -fsynopsys --std=08 adc_tf.vhd
~/workspace/src$ ghdl -e -fexplicit -fsynopsys --std=08 ADC_tf
~/workspace/src$ ghdl -r ADC_tf --vcd=ADC_tf.vcd --stop-time=2173731ns
~/workspace/src$ ghdl clean && ghdl remove && rm *.o *.cf *.vcd ADC_tf
```

* Para analisar, elaborar e executar csv_tb (testbench que usa arquivo csv), digite os seguinte comandos:

```
~/workspace/src$ ghdl -a -fexplicit -fsynopsys --std=08 adc_tf_csv.vhd
~/workspace/src$ ghdl -e -fexplicit -fsynopsys --std=08 csv_tb
~/workspace/src$ ghdl -r csv_tb
~/workspace/src$ ghdl clean && ghdl remove && rm *.o *.cf csv_tb
```

* Para analisar e elaborar ADC_top (preparação para escrever numa board), digite os seguinte comandos:

```
~/workspace/src$ ghdl -a -fexplicit -fsynopsys --std=08 adc_top.vhd
~/workspace/src$ ghdl -e -fexplicit -fsynopsys --std=08 ADC_top
~/workspace/src$ ghdl clean && ghdl remove && rm *.o *.cf ADC_top
```

### Autor

Lincoln Uehara
