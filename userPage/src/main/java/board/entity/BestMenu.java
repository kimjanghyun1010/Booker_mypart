package board.entity;

import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.Table;

import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "best_menu")
@NoArgsConstructor
@Data
public class BestMenu {
	@Id // 엔티티의 PK(기본키)
	@GeneratedValue(strategy = GenerationType.AUTO) // 데이터베이스에서 제공하는 기본키 생성 전략을 따름
	private int id;

	private String storeNumber;
	private String serviceImage;
	private String serviceName;
	private String servicePrice;
	private String serviceExplanation;
}
